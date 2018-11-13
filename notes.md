# Procedures

- open ufw
- change `default.conf`
- change ip address in `frontend/scripts`
- fst/executable/fst.ml: change output_img dir; add extra code in main function
- fst/fstserver.py: location of images
- re-build executables;
- change image size if necessary
- copy `fronteend/bower_components` scripts if does not exist
- make sure the js version is right 

In `fst/` and `inception/`:
```
gunicorn -w 2 -b 138.68.155.178:5000 myserver:app --daemon
gunicorn -w 2 -b 138.68.155.178:5001 fstserver:app --daemon
```

start frontend server:
```
docker run --name nginx -p 8080:8080 -v $HOME/Tmp/owl-demo/frontend/:/usr/share/nginx/html -v $HOME/Tmp/owl-demo/default.conf:/etc/nginx/conf.d/default.conf -v /tmp/:/usr/share/nginx/tmp-d nginx
```
or
```
docker run --name nginx -p 80:80 -v $HOME/Code/owl-demo/frontend/:/usr/share/nginx/html -v $HOME/Code/owl-demo/default.conf:/etc/nginx/conf.d/default.conf -v $HOME/Code/owl-demo/fst/fst_img:/usr/share/nginx/fst_img -d nginx
```
