open Owl
open Owl_types
open Algodiff.S

open Neural
open Neural.S
open Neural.S.Graph

let channel_last = true (* The same in Keras Conv layer *)
let include_top = true  (* if false, no final Dense layer *)
let img_size = 299      (* include_top = true means img_size have to be exact 299 *)
let obtain_input_shape () = None 

let conv2d_bn ?(padding=SAME) kernel stride x =  
  let open Owl_neural_graph in
  x |> conv2d ~padding kernel stride 
    |> normalisation ~training:false ~axis:3 (* color channel on 3rd dim*)
    |> activation Activation.Relu 

let model () = 
  let nn = input [|img_size;img_size;3|]
    |> conv2d_bn [|3;3;3;32|] [|2;2|]  ~padding:VALID
    |> conv2d_bn [|3;3;32;32|] [|1;1|] ~padding:VALID
    |> conv2d_bn [|3;3;32;64|] [|1;1|] 
    |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID (*this parameter is not specified in keras*)

    |> conv2d_bn [|1;1;64;80|] [|1;1|]  ~padding:VALID
    |> conv2d_bn [|3;3;80;192|] [|1;1|]  ~padding:VALID
    |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID
  in

  let mix_typ1 in_shape bp_size nn = 
    
    let branch1x1 = nn 
      |> conv2d_bn [|1;1;in_shape;64|] [|1;1|] 
    in 
    let branch5x5 = nn
      |> conv2d_bn [|1;1;in_shape;48|] [|1;1|] 
      |> conv2d_bn [|5;5;48;64|]  [|1;1|]
    in
    let branch3x3dbl = nn 
      |> conv2d_bn [|1;1;in_shape;64|] [|1;1|] 
      |> conv2d_bn [|3;3;64;96|]  [|1;1|] 
      |> conv2d_bn [|3;3;96;96|]  [|1;1|] 
    in 
    let branch_pool = nn 
      |> avg_pool2d [|3;3|] [|1;1|] 
      |> conv2d_bn [|1;1;in_shape; bp_size |] [|1;1|]  (* the 192 doesn't change *)
    in 
    let nn = concatenate 3 [|branch1x1; branch5x5; branch3x3dbl; branch_pool|] in (* all of shape: (35, 35, * ) --> 256 *)
    nn
  
  in
  (* mix 0, 1, 2 *)
  (* 35 x 35 x 192 --> 35 x 35 x 256 --> 35 x 35 x 288 --> 35 x 35 x 288 *)
  let nn = nn |> mix_typ1 192 32 |> mix_typ1 256 64  |> mix_typ1 288 64 in

  (* mix 3 *)
  let mix_typ3 nn = 
    let branch3x3 = nn 
      |> conv2d_bn [|3;3;288;384|] [|2;2|]  ~padding:VALID 
    in
    let branch3x3dbl = nn 
      |> conv2d_bn [|1;1;288;64|] [|1;1|]
      |> conv2d_bn [|3;3;64;96|]  [|1;1|]
      |> conv2d_bn [|3;3;96;96|] [|2;2|]  ~padding:VALID 
    in 
    let branch_pool = nn 
      (* the padding type is not specified in keras structure *)
      |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID 
    in
    concatenate 3 [|branch3x3; branch3x3dbl; branch_pool|] 
  in
  (* 35 x 35 x 288 --> 17 x 17 x 768 *)
  let nn = nn |> mix_typ3 in 

  (* mix 4, 5, 6, 7 *)
  let mix_typ4 size nn = 
    let branch1x1 = nn
      |> conv2d_bn [|1;1;768;192|] [|1;1|] 
    in 
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
      |> avg_pool2d [|3;3|] [|1;1|] (*padding = 'SAME'*)
      |> conv2d_bn [|1;1; 768; 192|] [|1;1|]
    in
    concatenate 3 [|branch1x1; branch7x7; branch7x7dbl; branch_pool|] 
  in 
  (* 17 x 17 x 768 --> 17 x 17 x 768 --> 17 x 17 x 768 
    --> 17 x 17 x 768 --> 17 x 17 x 768 *)
  let nn = nn |> mix_typ4 128 |> mix_typ4 160 
              |> mix_typ4 160 |> mix_typ4 192 in 


  (* mix 8 *)
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
    let branch_pool = nn
      |> max_pool2d [|3;3|] [|2;2|] ~padding:VALID
    in
    concatenate 3 [|branch3x3; branch7x7x3; branch_pool|]
  in
  (* 17 x 17 x 768 --> 8 x 8 x 1280 *)
  let nn = nn |> mix_typ8 in 

  (* mix 9, 10*)
  let mix_typ9 input nn = 

    let branch1x1 = nn 
      |> conv2d_bn [|1;1;input;320|] [|1;1|]
    in

    let branch3x3 = nn 
      |> conv2d_bn [|1;1;input;384|] [|1;1|]
    in
    let branch3x3_1 = branch3x3 |> conv2d_bn [|1;3;384;384|] [|1;1|] in 
    let branch3x3_2 = branch3x3 |> conv2d_bn [|3;1;384;384|] [|1;1|] in 
    let branch3x3 = concatenate 3 [| branch3x3_1; branch3x3_2 |]
    in

    let branch3x3dbl = nn 
      |> conv2d_bn [|1;1;input;448|] [|1;1|]
      |> conv2d_bn [|3;3;448;384|]   [|1;1|]
    in 
    let branch3x3dbl_1 = branch3x3dbl |> conv2d_bn [|1;3;384;384|] [|1;1|]  in 
    let branch3x3dbl_2 = branch3x3dbl |> conv2d_bn [|3;1;384;384|] [|1;1|]  in 
    let branch3x3dbl = concatenate 3 [|branch3x3dbl_1; branch3x3dbl_2|] 
    in 

    let branch_pool = nn
      |> avg_pool2d [|3;3|] [|1;1|]
      |> conv2d_bn  [|1;1;input;192|] [|1;1|]
    in

    concatenate 3 [|branch1x1; branch3x3; branch3x3dbl; branch_pool|]
  
  in 
  (*  8 x 8 x 1280 -->  8 x 8 x 2048 -->  8 x 8 x 2048 *)
  let nn = nn |> mix_typ9 1280 |> mix_typ9 2048 in 

  let nn = nn 
    |> global_avg_pool2d 
    |> linear 1000 ~act_typ:Activation.Softmax
    |> get_network
  in print nn;
  nn