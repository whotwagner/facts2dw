> [!WARNING]  
> This repository has been moved to [https://codeberg.org/whotwagner/facts2dw](https://codeberg.org/whotwagner/facts2dw). Please visit the new location for the latest updates.

# facts2dw.rb
Simple script which converts ansible facts into dokuwiki-format and uploads it via xmlrpc-interface into dokuwiki			  
    								  
This script uses http-basic-authentication and ssl to login into dokuwiki. Ansible caches all the facts in <ANSIBLE-DIR>/facts so it is quite easy to import all facts into dokuwiki using the following line: 

```
for i in `ls *`; do facts2dw.rb $i; done		  
```    								  

To upload all the changes whenever they occur I would suggest using inotify.							  
    								  
It is very easy to change this script to use puppet-facts instead of ansible-facts. If puppetdb is installed all the facts can fetched via the rest interface. It's just a matter of few lines. Of course the jason-structur will look different, but it will be easy to modify this very simple script. I would recommend to use the debug-code which executes 'pp', to dump the jason-hash.       

BTW: don't forget to configure the xmlrpc-access in dokuwiki proberly!
                                                                      
Copyright (C) 2015 Wolfgang Hotwagner(wolfgang.hotwagner@toscom.at)   

