# Prerequisite 

- Install python, then pip, gunicorn
- Install opam (cold), then install bwrap (dh-autoreconf, libcap-dev, autogen) configure make installi; then follow Dockerfile
- Install node 
- Install imagemagick


# Procedures

- open ufw
- change `default.conf`
- change ip address in `frontend/scripts`
- fst/executable/fst.ml: change output\_img dir; add extra code in main function
- fst/fstserver.py: location of images
- re-build executables;
- Use external ip address everywhere
In `fst/` and `inception/`:
```
gunicorn -w 1 -b 162.209.96.234:5000 inception_server:app --daemon
gunicorn -w 1 -b 162.209.96.234:5001 fst_server:app --daemon
```

start frontend server:
```
docker run --name nginx -p 80:80 -v $HOME/owl-demo/frontend/:/usr/share/nginx/html -v $HOME/owl-demo/default.conf:/etc/nginx/conf.d/default.conf -v $HOME/owl-demo/fst/fst_img/:/usr/share/nginx/fst_img -v /tmp/:/usr/share/nginx/tmp -d nginx
```
