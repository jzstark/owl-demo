from flask import Flask
from flask import request, jsonify
from flask_cors import CORS, cross_origin
from werkzeug import secure_filename
import os, subprocess, json
from subprocess import call
import pickle
import hashlib

app = Flask(__name__)
CORS(app)

img_dir = 'mrcnn_img/'
app.config['UPLOAD_FOLDER'] = img_dir

@app.route('/')
def hello_world():
    return 'Hello, MRCNN World!'

ALLOWED_EXTENSIONS = set(['ppm', 'png', 'jpg', 'jpeg', 'PNG', 'JPG', 'JPEG'])

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

        f = request.files.get('uploadfile', '')
        if f and allowed_file(f.filename):
            filename = secure_filename(f.filename)
            base_ext = os.path.splitext(filename)

            hashed_base = hashlib.md5(base_ext[0]).hexdigest() #hash to avoid weird names
            hashed_base = hashed_base[0:7]
            filename = hashed_base + base_ext[1]

            file_addr = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            f.save(file_addr)

            #if base_ext[1] != '.png' or base_ext[1] != '.PNG':
            png_file_addr = hashed_base + '.png'
            png_file_addr = os.path.join(app.config['UPLOAD_FOLDER'], png_file_addr)
            try:
                # Change the format to png, and reszie to no larger than 1800 if necessary
                # Note that however, the "long" image of size, e.g., 1799 x 100000 might still be unreszied; but in that case, bite the dust you evil S.O.B, this is just a  demo site that has pitfalls everywhere, so save your testing somewhere else. 
                subprocess.check_output(["convert", file_addr, "-resize", "1800x>", "-auto-orient", png_file_addr])
                file_addr = png_file_addr
            except subprocess.CalledProcessError as e:
                print(e.output)
                raise
                
            try:
                resp = subprocess.check_output(['executable/mrcnn_demo.exe', file_addr])
            except subprocess.CalledProcessError as e:
                print(e.output)
                raise
                
            #new_img = img_dir + resp
            new_img = resp

            # Get counter number
            with open('counter.txt', 'r+') as f:
                old_counter = int(next(f))
                new_counter = old_counter + 1
                f.seek(0)
                f.write(str(new_counter) + '\n')
                f.truncate()
            return jsonify([new_counter, new_img])
        else:
            app.logger.info('ext name error')
            return [] #jsonify(error='ext name error')
    return ""


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5002, debug=True)
