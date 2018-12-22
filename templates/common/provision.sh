#!/bin/bash

echo "Configuring user....."
sudo mkdir -p "/home/${username}/.cache"
sudo touch "/home/${username}/.cache/motd.legal-displayed"
sudo touch "/home/${username}/.sudo_as_admin_successful"
sudo chown -R "${username}:${username}" "/home/${username}"

echo "Configuring MOTD....."
sudo rm -rf /etc/motd
sudo rm -rf /var/run/motd
sudo rm -rf /etc/update-motd.d/*
sudo tee /etc/motd > /dev/null <<"EOF"
              
                    `..    `.`                    
                 `/smM/    :Mms/`                 
             `-ohNMMMM/    :MMMMm   `             
         `./ymMMMMMMNh-    :MMMMm   sy/.`         
        :dNMMMMMNms:.      :MMMMm   hMMNd:        
        +MMMMMh+-  ./y:    :MMMMm   hMMMM+        
        +MMMMd   +hNMM/    :MMMMm   hMMMM+        
        +MMMMd   mMMMM+....+MMMMm   hMMMM+        
        +MMMMd   mMMMMNNNNNNMMMMm   hMMMM+        
        +MMMMd   mMMMMMNNNNMMMMMm   hMMMM+        
        +MMMMd   mMMMMo----+MMMMm   hMMMM+        
        +MMMMd   mMMMM/    :MMNdo   hMMMM+        
        +MMMMd   mMMMM/    -y/.` -+yNMMMM+        
        :dMMMd   mMMMM/      `:sdNMMMMMMd:        
         `.+yy   mMMMM/    .hNMMMMMMmy+.`         
             `   mMMMM/    :MMMMNdo-`             
                 `/smM/    :Mmy/.                 
                    `..    `-`                    
                                                  
Welcome to HashiCorp demo! And yes, all demos should be done live.                                                
EOF