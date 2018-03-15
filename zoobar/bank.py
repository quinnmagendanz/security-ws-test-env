from zoodb import *
from debug import *
from sqlalchemy.ext.declarative import DeclarativeMeta
import json
import time
import auth_client

def transfer(sender, recipient, zoobars, token):
    if (not auth_client.check_token(sender, token)):
        raise ValueError()

    bankdb = bank_setup()
    senderp = bankdb.query(Bank).get(sender)
    recipientp = bankdb.query(Bank).get(recipient)

    sender_balance = senderp.zoobars - zoobars
    recipient_balance = recipientp.zoobars + zoobars

    if sender_balance < 0 or recipient_balance < 0 or zoobars < 0:
        raise ValueError()

    senderp.zoobars = sender_balance
    recipientp.zoobars = recipient_balance
    bankdb.commit()

    transfer = Transfer()
    transfer.sender = sender
    transfer.recipient = recipient
    transfer.amount = zoobars
    transfer.time = time.asctime()
    transferdb = transfer_setup()
    transferdb.add(transfer)
    transferdb.commit()

def init_account(username):
    bank_db = bank_setup()
    new_account = Bank()
    new_account.username = username
    bank_db.add(new_account)
    bank_db.commit()

def balance(username):
    db = bank_setup()
    account = db.query(Bank).get(username)
    return account.zoobars

def get_log(username):
    db = transfer_setup()
    result = db.query(Transfer).filter(or_(Transfer.sender==username,
                                             Transfer.recipient==username))
    
    return_list = []
    for u in result:
        element = u.__dict__
        element.pop('_sa_instance_state', None)
        return_list.append(element)
    #print(return_list)
    return return_list
