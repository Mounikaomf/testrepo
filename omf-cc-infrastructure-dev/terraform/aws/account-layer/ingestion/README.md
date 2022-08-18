This terraform project creates SFTP for datasource integration. It has default "test" user with access to everything. 

NOTE: this code should be applied in 3 steps. 
1. Run the code, it would create SFTP and SSM parameters for SSH public keys. 
2. update SSM parameters by setting correct ssh public keys to them
3. Run IaaC once again, so that terraform would pick up SSM parameters and apply them to sftp users. 

