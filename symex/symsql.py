## This module wraps SQLalchemy's methods to be friendly to
## symbolic / concolic execution.

import fuzzy
import sqlalchemy.orm

oldget = sqlalchemy.orm.query.Query.get
def newget(query, primary_key_val):
  ## Exercise 8: your code here.
  ##
  ## Find the object with the primary key "primary_key" in SQLalchemy
  ## query object "query", and do so in a symbolic-friendly way.
  ##
  ## Hint: given a SQLalchemy row object r, you can find the name of
  ## its primary key using r.__table__.primary_key.columns.keys()[0]

  rows = query.all()
  for r in rows:
    p_key = r.__table__.primary_key.columns.keys()[0];
    if (primary_key_val == getattr(r, p_key)):
      return r
  return None

sqlalchemy.orm.query.Query.get = newget
