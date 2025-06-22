import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# CONFIGURAÇÕES DO SEU E-MAIL
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_EMAIL = "isabellevasquezoliveira@gmail.com"
SMTP_PASSWORD = "japb vwew wxwb bqiu"

def send_otp_email(destinatario: str, otp: str):
    assunto = "Seu código OTP"
    corpo = f"Seu código de verificação é: {otp}"

    msg = MIMEMultipart()
    msg["From"] = SMTP_EMAIL
    msg["To"] = destinatario
    msg["Subject"] = assunto

    msg.attach(MIMEText(corpo, "plain"))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.sendmail(SMTP_EMAIL, destinatario, msg.as_string())
            print(f"[INFO] OTP enviado para {destinatario}")
    except Exception as e:
        print(f"[ERRO] Falha ao enviar e-mail: {e}")
