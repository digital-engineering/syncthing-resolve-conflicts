```
            _____                    _____                    _____          
           /\    \                  /\    \                  /\    \         
          /::\    \                /::\    \                /::\    \        
         /::::\    \              /::::\    \              /::::\    \       
        /::::::\    \            /::::::\    \            /::::::\    \      
       /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \     
      /:::/__\:::\    \        /:::/__\:::\    \        /:::/  \:::\    \    
      \:::\   \:::\    \      /::::\   \:::\    \      /:::/    \:::\    \   
    ___\:::\   \:::\    \    /::::::\   \:::\    \    /:::/    / \:::\    \  
   /\   \:::\   \:::\    \  /:::/\:::\   \:::\____\  /:::/    /   \:::\    \ 
  /::\   \:::\   \:::\____\/:::/  \:::\   \:::|    |/:::/____/     \:::\____\
  \:::\   \:::\   \::/    /\::/   |::::\  /:::|____|\:::\    \      \::/    /
   \:::\   \:::\   \/____/  \/____|:::::\/:::/    /  \:::\    \      \/____/ 
    \:::\   \:::\    \            |:::::::::/    /    \:::\    \             
     \:::\   \:::\____\           |::|\::::/    /      \:::\    \            
      \:::\  /:::/    /           |::| \::/____/        \:::\    \           
       \:::\/:::/    /            |::|  ~|               \:::\    \          
        \::::::/    /             |::|   |                \:::\    \         
         \::::/    /              \::|   |                 \:::\____\        
          \::/    /                \:|   |                  \::/    /        
           \/____/                  \|___|                   \/____/         
```                                                                             

# syncthing-resolve-conflicts

## Script for deleting duplicate `\*sync-conflict\*` files created by Syncthing.

### Usage:
```
./resolve-conflicts.sh <directory>
```

### Depends on:
- find


### Description

**syncthing-resolve-conflicts** is a bash script that uses the Unix `find` 
utility to locate files matching the pattern "*sync-conflict*". For each 
`sync-conflict` file that is found, the corresponding non-conflict file is
matched. Then the sha256sum of each file in the pair is calculated. If the 
sums are equal, the redundant `sync-conflict` file is deleted. Otherwise, a 
message is shown so the user can investigate manually.
