from debug import *
from zoodb import *
import rpclib
from os import urandom
import pbkdf2
import hashlib
import random
from base64 import b64encode

def newtoken(db, person):
    hashinput = "%s%.10f" % (person.password, random.random())
    # TODO(magendanz) MD5 is depricated
    person.token = hashlib.md5(hashinput).hexdigest()
    db.commit()
    return person.token

def login(username, password):
    db = cred_setup()
    person = db.query(Cred).get(username)
    if not person:
        return None
    check_pass = pbkdf2.PBKDF2(str(password), person.salt).hexread(32)
    if person.password == check_pass:
        return newtoken(db, person)
    else:
        return None

def register(username, password):
    cred_db = cred_setup()
    person_db = person_setup()
    person = cred_db.query(Cred).get(username)
    if person:
        return None
    new_cred = Cred()
    new_cred.username = username
    
    salt = b64encode(urandom(64)).decode('utf-8')
    hash_pass = pbkdf2.PBKDF2(str(password), salt).hexread(32)
    new_cred.password = hash_pass
    new_cred.salt = salt

    cred_db.add(new_cred)
    cred_db.commit()
    new_person = Person()
    new_person.username = username
    person_db.add(new_person)
    person_db.commit()
    return newtoken(cred_db, new_cred)

def check_token(username, token):
    db = cred_setup()
    person = db.query(Cred).get(username)
    if person and person.token == token:
        return True
    else:
        return False

