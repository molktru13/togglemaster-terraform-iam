import os
import sys
import threading
import json
import uuid
import time
import logging
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
from flask import Flask, jsonify, request
from dotenv import load_dotenv

# Configura o logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
log = logging.getLogger(__name__)

# Carrega .env para desenvolvimento local
load_dotenv()

# --- Configuração ---
AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")
IS_TESTING = os.getenv("TESTING", "false").lower() == "true"

sqs_client = None
dynamodb_client = None

if not IS_TESTING:
    if not all([AWS_REGION, SQS_QUEUE_URL, DYNAMODB_TABLE_NAME]):
        log.critical("Erro: AWS_REGION, AWS_SQS_URL e AWS_DYNAMODB_TABLE devem ser definidos.")
        sys.exit(1)

    try:
        session = boto3.Session(region_name=AWS_REGION)
        sqs_client = session.client("sqs")
        dynamodb_endpoint = os.getenv("AWS_DYNAMODB_ENDPOINT")
        if dynamodb_endpoint:
            dynamodb_client = session.client("dynamodb", endpoint_url=dynamodb_endpoint)
            log.info(f"Usando endpoint DynamoDB customizado: {dynamodb_endpoint}")
        else:
            dynamodb_client = session.client("dynamodb")
        log.info(f"Clientes Boto3 inicializados na região {AWS_REGION}")
    except NoCredentialsError:
        log.critical("Credenciais da AWS não encontradas. Verifique seu ambiente.")
        sys.exit(1)
    except Exception as e:
        log.critical(f"Erro ao inicializar o Boto3: {e}")
        sys.exit(1)


# --- SQS Worker ---
def process_message(message):
    """Processa uma única mensagem SQS e a insere no DynamoDB"""
    try:
        log.info(f"Processando mensagem ID: {message['MessageId']}")
        body = json.loads(message['Body'])

        event_id = str(uuid.uuid4())
        item = {
            'event_id': {'S': event_id},
            'user_id': {'S': body['user_id']},
            'flag_name': {'S': body['flag_name']},
            'result': {'BOOL': body['result']},
            'timestamp': {'S': body['timestamp']}
        }

        dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item=item
        )

        log.info(f"Evento {event_id} (Flag: {body['flag_name']}) salvo no DynamoDB.")

        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message['ReceiptHandle']
        )

    except json.JSONDecodeError:
        log.error(f"Erro ao decodificar JSON da mensagem ID: {message['MessageId']}")
    except ClientError as e:
        log.error(f"Erro do Boto3 (DynamoDB ou SQS) ao processar {message['MessageId']}: {e}")
    except Exception as e:
        log.error(f"Erro inesperado ao processar {message['MessageId']}: {e}")


def sqs_worker_loop():
    """Loop principal do worker que ouve a fila SQS"""
    log.info("Iniciando o worker SQS...")
    while True:
        try:
            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20
            )

            messages = response.get('Messages', [])
            if not messages:
                continue

            log.info(f"Recebidas {len(messages)} mensagens.")

            for message in messages:
                process_message(message)

        except ClientError as e:
            log.error(f"Erro do Boto3 no loop principal do SQS: {e}")
            time.sleep(10)
        except Exception as e:
            log.error(f"Erro inesperado no loop principal do SQS: {e}")
            time.sleep(10)


# --- Servidor Flask ---
app = Flask(__name__)


@app.route('/health')
def health():
    return jsonify({"status": "ok"})


@app.route('/analytics', methods=['GET'])
def analytics():
    """Consulta os eventos de avaliação persistidos no DynamoDB"""
    try:
        limit = request.args.get('limit', 20, type=int)
        response = dynamodb_client.scan(
            TableName=DYNAMODB_TABLE_NAME,
            Limit=min(limit, 100)
        )
        items = response.get('Items', [])
        events = []
        for item in items:
            events.append({
                'event_id': item['event_id']['S'],
                'user_id': item['user_id']['S'],
                'flag_name': item['flag_name']['S'],
                'result': item['result']['BOOL'],
                'timestamp': item['timestamp']['S']
            })
        return jsonify({"count": len(events), "events": events})
    except ClientError as e:
        log.error(f"Erro ao consultar o DynamoDB: {e}")
        return jsonify({"error": "Falha ao consultar o DynamoDB"}), 500
    except Exception as e:
        log.error(f"Erro inesperado ao consultar o DynamoDB: {e}")
        return jsonify({"error": "Erro interno"}), 500


def start_worker():
    """Inicia o worker SQS em uma thread separada"""
    worker_thread = threading.Thread(target=sqs_worker_loop, daemon=True)
    worker_thread.start()


if not IS_TESTING:
    start_worker()

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8005))
    app.run(host='0.0.0.0', port=port, debug=False)  # nosec B104
