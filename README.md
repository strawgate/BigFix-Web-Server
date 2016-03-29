# BigFix-Web-Server
This code takes a simple website, flattens it, and provides the necessary information to host a website from a BigFix Server or Relay.

###Steps
1. Put web template in "Original"
2. Run Flatten.ps1
3. Copy Output/ID to "Program Files (x86)\BigFix Enterprise\BES Server\wwwrootbes\bfmirror\downloads\sha1" on your BigFix Server
4. Take the output from Flatten.ps1 and put it in a fixlet, action it against the relay/bfserver you want to host the website
5. Navigate to: http://yourserver:52311/bfmirror/downloads/ACTIONID/HTMLIDFROMFLATTPS1