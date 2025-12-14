import os
import json
import psycopg2
import requests

DB_HOST = os.environ['DB_HOST']
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
DB_NAME = os.environ['DB_NAME']
GPT_KEY = os.environ['GPT_KEY']

def handler(event, context):
    data = json.loads(event['body'])
    session_id = data['sessionId']
    message = data['message']

    # Подключение к БД
    conn = psycopg2.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, dbname=DB_NAME)
    cur = conn.cursor()

    # Вызов YandexGPT
    headers = {"Authorization": f"Bearer {GPT_KEY}"}
    payload = {"prompt": message, "temperature":0.7, "max_tokens":150}
    response = requests.post("https://api.ai.yandex/gpt-inference/v1/models/text-bison:generate", 
                             headers=headers, json=payload)
    answer = response.json()["result"]["text"]

    # Сохранение диалога
    cur.execute("INSERT INTO messages (session_id, user_message, bot_message) VALUES (%s,%s,%s)",
                (session_id, message, answer))
    conn.commit()
    cur.close()
    conn.close()

    return {
        "statusCode": 200,
        "body": json.dumps({"reply": answer})
    }

