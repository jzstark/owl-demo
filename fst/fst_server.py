from flask import Flask
from flask import request, jsonify
from flask_cors import CORS, cross_origin
from werkzeug import secure_filename
import os, subprocess, json
from subprocess import call
import pickle
import sys

app = Flask(__name__)
CORS(app)

#img_dir = '/tmp/'
img_dir = 'fst_img/'
app.config['UPLOAD_FOLDER'] = img_dir

cache_dict = "current_img_cache.p"

h = 325
w = 325

@app.route('/')
def hello_world():
    return 'Hello, World! Hello, Shiroe!\n'

ALLOWED_EXTENSIONS = set(['ppm', 'png', 'jpg', 'JPG', 'jpeg', 'JPEG', 'gif', 'PNG', 'svg'])

def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

@app.route('/counter', methods=['GET', 'POST', 'OPTIONS'])
def counter():
    with open('counter.txt', 'r+') as f:
        counter = int(next(f))
    return jsonify(counter)

@app.route('/upload', methods=['GET', 'POST', 'OPTIONS'])
def index():
    if request.method == 'POST':
        # files = request.files.getlist('file[]')

        f = request.files.get('uploadfile', '')
        s = request.form.get('style', '')
        if f and allowed_file(f.filename):
            filename = secure_filename(f.filename)
            file_addr = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            f.save(file_addr)

            img_addr, img_extension = os.path.splitext(file_addr)
            new_img_addr = img_addr + '.ppm'
            # comm = "convert %s -geometry %dx%d^ -gravity center -crop %dx%d+0+0 %s" % (file_addr, h, w, h, w, new_img_addr)
            size = subprocess.check_output(['identify', '-format', '%w,%h', file_addr])
            size = size.split(',')
            img_w = int(size[0])
            img_h = int(size[1])
            if (img_w < img_h) :
                comm = "convert %s -geometry %dx %s" % (file_addr, w, new_img_addr)
            else:
                comm = "convert %s -geometry x%d %s" % (file_addr, h, new_img_addr)
            os.system(comm)
            resp = subprocess.check_output(['executable/fst.exe', new_img_addr, s])
            # Remove log info 
            resp = resp.splitlines()[-1]
            resp = img_dir + resp

            cache = {}
            cache[file_addr] = {s : resp}
            pickle.dump(cache, open(cache_dict, "wb" ))
            #d = json.loads(resp)
            # Get counter number
            with open('counter.txt', 'r+') as f:
                old_counter = int(next(f))
                new_counter = old_counter + 1
                f.seek(0)
                f.write(str(new_counter) + '\n')
                f.truncate()
            print jsonify([new_counter, resp])
            return jsonify([new_counter, resp])
        else:
            app.logger.info('ext name error')
            return [] #jsonify(error='ext name error')
    return ""


@app.route('/redraw', methods=['GET', 'POST'])
def redraw():
    fname = request.args.get('filename', '')
    s = request.args.get('style', '')
    if fname:
        filename = secure_filename(fname)
        print filename
        file_addr = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        cache = pickle.load(open(cache_dict, "rb"))
        if (file_addr in cache) and (cache[file_addr].has_key(s)):
            resp = cache[file_addr][s]
        else:
            img_addr, img_extension = os.path.splitext(file_addr)
            new_img_addr = img_addr + '.ppm'
            # comm = "convert " + file_addr +  " -geometry 256x256^ -gravity center -crop 256x256+0+0 " + new_img_addr
            size = subprocess.check_output(['identify', '-format', '%w,%h', file_addr])
            size = size.split(',')
            img_w = int(size[0])
            img_h = int(size[1])
            if (img_w < img_h) :
                comm = "convert %s -geometry %dx %s" % (file_addr, w, new_img_addr)
            else:
                comm = "convert %s -geometry x%d %s" % (file_addr, h, new_img_addr)
            os.system(comm)
            resp = subprocess.check_output(['executable/fst.exe', new_img_addr, s])
            # Remove log info 
            resp = resp.splitlines()[-1]

            resp = img_dir + resp


            cache[file_addr][s] = resp
            pickle.dump(cache, open(cache_dict, "wb" ))

        with open('counter.txt', 'r+') as f:
            old_counter = int(next(f))
            new_counter = old_counter + 1
            f.seek(0)
            f.write(str(new_counter) + '\n')
            f.truncate()
        return jsonify([new_counter, resp])
    return ""

if __name__ == "__main__":
    app.run(host='0.0.0.0',port=5001,debug=True)
