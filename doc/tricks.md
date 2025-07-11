# Various tips and tricks

## Error at SSH connection

If you meet an error like that when trying to SSH into an Azure VM :

```txt
Received disconnect from UNKNOWN port 65535:2: Too many authentication failures
Disconnected from UNKNOWN port 65535
```

It probably means that your SSH client tries too many keys before reaching the right one — and the server closes the connection.

### What you can do

Unload unused keys from you ssh-agent and reload those you need :

```bash
ssh-add -D ### unload all keys from your SSH-agent
ssh-add ~/.ssh/target.pem ### reload target.pem in the agent
```

## HAProxy

To launch a HA Proxy dry run :

```bash
haproxy -c -V -f /etc/haproxy/haproxy.cfg
```