#!/usr/bin/env python2

import rpclib
import sys
import auth_client
from debug import *

class AuthRpcServer(rpclib.RpcServer):
    def rpc_register(self, username, token):
        return auth_client.register(username, token)

    def rpc_login(self, username, token):
        return auth_client.login(username, token)

    def rpc_check_token(self, username, token):
        return auth_client.check_token(username, token)
    

(_, dummy_zookld_fd, sockpath) = sys.argv

s = AuthRpcServer()
s.run_sockpath_fork(sockpath)
