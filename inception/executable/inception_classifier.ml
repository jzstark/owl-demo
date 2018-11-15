open Owl
open Owl_types

open Neural.S
open Neural.S.Graph

let channel_last = true (* The same in Keras Conv layer *)
let include_top = true  (* if false, no final Dense layer *)
let img_size = 250      (* include_top = true means img_size have to be exact 299 *)

let weight_file = "inception_owl.weight"

let conv2d_bn ?(padding=SAME) kernel stride nn =
  conv2d ~padding kernel stride nn
  |> normalisation ~training:false ~axis:3
  |> activation Activation.Relu

let mix_typ1 in_shape bp_size nn =
  let branch1x1 = conv2d_bn [|1;1;in_shape;64|] [|1;1|] nn in
  let branch5x5 = nn
    |> conv2d_bn [|1;1;in_shape;48|] [|1;1|]
    |> conv2d_bn [|5;5;48;64|] [|1;1|]
  in
  let branch3x3dbl = nn
    |> conv2d_bn [|1;1;in_shape;64|] [|1;1|]
    |> conv2d_bn [|3;3;64;96|]  [|1;1|]
    |> conv2d_bn [|3;3;96;96|]  [|1;1|]
  in
  let branch_pool = nn
    |> avg_pool2d [|3;3|] [|1;1|]
    |> conv2d_bn [|1;1;in_shape; bp_size |] [|1;1|]
  in
  concatenate 3 [|branch1x1; branch5x5; branch3x3dbl; branch_pool|]

let mix_typ3 nn =
  let branch3x3 = conv2d_bn [|3;3;288;384|] [|2;2|] ~padding:VALID nn in
  let branch3x3dbl = nn
    |> conv2d_bn [|1;1;288;64|] [|1;1|]
    |> conv2d_bn [|3;3;64;96|] [|1;1|]
    |> conv2d_bn [|3;3;96;96|] [|2;2|] ~padding:VALID
  in
  let branch_pool = max_pool2d [|3;3|] [|2;2|] ~padding:VALID nn in
  concatenate 3 [|branch3x3; branch3x3dbl; branch_pool|]

let mix_typ4 size nn =
  let branch1x1 = conv2d_bn [|1;1;768;192|] [|1;1|] nn in
  let branch7x7 = nn
    |> conv2d_bn [|1;1;768;size|] [|1;1|]
    |> conv2d_bn [|1;7;size;size|] [|1;1|]
    |> conv2d_bn [|7;1;size;192|] [|1;1|]
  in
  let branch7x7dbl = nn
    |> conv2d_bn [|1;1;768;size|] [|1;1|]
    |> conv2d_bn [|7;1;size;size|] [|1;1|]
    |> conv2d_bn [|1;7;size;size|] [|1;1|]
    |> conv2d_bn [|7;1;size;size|] [|1;1|]
    |> conv2d_bn [|1;7;size;192|] [|1;1|]
  in
  let branch_pool = nn
    |> avg_pool2d [|3;3|] [|1;1|] (* padding = SAME *)
    |> conv2d_bn [|1;1; 768; 192|] [|1;1|]
  in
  concatenate 3 [|branch1x1; branch7x7; branch7x7dbl; branch_pool|]

let mix_typ8 nn =
  let branch3x3 = nn
    |> conv2d_bn [|1;1;768;192|] [|1;1|]
    |> conv2d_bn [|3;3;192;320|] [|2;2|] ~padding:VALID
  in
  let branch7x7x3 = nn
    |> conv2d_bn [|1;1;768;192|] [|1;1|]
    |> conv2d_bn [|1;7;192;192|] [|1;1|]
    |> conv2d_bn [|7;1;192;192|] [|1;1|]
    |> conv2d_bn [|3;3;192;192|] [|2;2|] ~padding:VALID
  in
  let branch_pool = max_pool2d [|3;3|] [|2;2|] ~padding:VALID nn in
  concatenate 3 [|branch3x3; branch7x7x3; branch_pool|]

let mix_typ9 input nn =
  let branch1x1 = conv2d_bn [|1;1;input;320|] [|1;1|] nn in
  let branch3x3 = conv2d_bn [|1;1;input;384|] [|1;1|] nn in
  let branch3x3_1 = branch3x3 |> conv2d_bn [|1;3;384;384|] [|1;1|] in
  let branch3x3_2 = branch3x3 |> conv2d_bn [|3;1;384;384|] [|1;1|] in
  let branch3x3 = concatenate 3 [| branch3x3_1; branch3x3_2 |] in
  let branch3x3dbl = nn |> conv2d_bn [|1;1;input;448|] [|1;1|] |> conv2d_bn [|3;3;448;384|] [|1;1|] in
  let branch3x3dbl_1 = branch3x3dbl |> conv2d_bn [|1;3;384;384|] [|1;1|]  in
  let branch3x3dbl_2 = branch3x3dbl |> conv2d_bn [|3;1;384;384|] [|1;1|]  in
  let branch3x3dbl = concatenate 3 [|branch3x3dbl_1; branch3x3dbl_2|] in
  let branch_pool = nn |> avg_pool2d [|3;3|] [|1;1|] |> conv2d_bn [|1;1;input;192|] [|1;1|] in
  concatenate 3 [|branch1x1; branch3x3; branch3x3dbl; branch_pool|]

let make_network img_size =
  input [|img_size;img_size;3|]
  |> conv2d_bn [|3;3;3;32|] [|2;2|] ~padding:VALID
  |> conv2d_bn [|3;3;32;32|] [|1;1|] ~padding:VALID
  |> conv2d_bn [|3;3;32;64|] [|1;1|]
  |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID
  |> conv2d_bn [|1;1;64;80|] [|1;1|] ~padding:VALID
  |> conv2d_bn [|3;3;80;192|] [|1;1|] ~padding:VALID
  |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID
  |> mix_typ1 192 32 |> mix_typ1 256 64 |> mix_typ1 288 64
  |> mix_typ3
  |> mix_typ4 128 |> mix_typ4 160 |> mix_typ4 160 |> mix_typ4 192
  |> mix_typ8
  |> mix_typ9 1280 |> mix_typ9 2048
  |> global_avg_pool2d
  |> linear 1000 ~act_typ:Activation.(Softmax 1)
  |> get_network

let get_input_data img_name = 
  let img = ImageUtils.load_ppm img_name in
  let shape = Dense.Ndarray.S.shape img in
  let shape = Array.append [|1|] shape in
  let img = Dense.Ndarray.S.reshape img shape in 
  
  (* Preprocessing input image data to range [-1, 1] *)
  let img = Dense.Ndarray.S.div_scalar img 255. in 
  let img = Dense.Ndarray.S.sub_scalar img 0.5  in
  let img = Dense.Ndarray.S.mul_scalar img 2.   in
  img

let decode_predictions ?(top=5) preds = 
  let h = Owl_io.marshal_from_file "imagenet1000.dict" in 
  let tp = Dense.Matrix.S.top preds top in 
  Printf.printf "\nTop %d Predictions:\n" top;
  Array.iteri (fun i x -> 
    Printf.printf "Prediction #%d (%.2f%%) : " i ((Dense.Matrix.S.get preds x.(0) x.(1)) *. 100.);
    Printf.printf "%s\n" (Hashtbl.find h x.(1)) 
  ) tp

let to_json ?(top=5) preds = 
  let assos = Array.make top "" in 
  let h = Owl_io.marshal_from_file "imagenet1000.dict" in 
  let tp = Dense.Matrix.S.top preds top in 

  Array.iteri (fun i x -> 
    let cls  = Hashtbl.find h x.(1) in 
    let prop = Dense.Matrix.S.get preds x.(0) x.(1) in 
    let p = "{\"class\":\"" ^ cls ^ "\", \"prop\": " ^ (string_of_float prop) ^ "}," in 
    Array.set assos i p 
  ) tp;

  let str  = Array.fold_left (^) "" assos in 
  let str  = String.sub str 0 ((String.length str) - 1) in
  let json = "[" ^ str ^ " ]" in 
  Printf.printf "%s" json;
  json

let _ = 
  let img_name = Sys.argv.(1) in
  let nn = make_network img_size in
  Graph.init nn;
  Graph.load_weights nn weight_file;
  let img_ppm = get_input_data img_name in 
  let preds = Graph.model nn img_ppm in 
  to_json preds


