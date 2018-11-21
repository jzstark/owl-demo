open Owl
module N = Dense.Ndarray.S

open Mrcnn
module C = Configuration

(* Script used for the web demo of Mask R-CNN. *)

let () = C.set_image_size 512 (* 768 *)


let () =
  Owl_log.set_level FATAL;
  (* Build the network once. *)
  let fun_detect = Model.detect () in

  let eval out_dir src =

    Filename.set_temp_dir_name out_dir;

    let Model.({rois; class_ids; scores; masks}) = fun_detect src in
    let img_arr = Image.img_to_ndarray src in
    let filename = Filename.basename src in
    let format = Images.guess_format src in
    let pref, ext = Images.get_extension filename in 
    let out_loc = Filename.temp_file pref ("." ^ ext) in
    (* add the bounding boxes and the masks to the picture *)
    Visualise.display_masks img_arr rois masks class_ids;
    let camlimg = Image.img_of_ndarray img_arr in
    Visualise.display_labels camlimg rois class_ids scores;
    Image.save out_loc format camlimg;
    Unix.chmod out_loc 0o775;
    (* if Array.length class_ids > 0 then
      Visualise.print_results class_ids rois scores
    else Printf.printf "No objects detected.\n"
    *)
    Printf.printf "%s" out_loc
  in

  eval "mrcnn_img" Sys.argv.(1)
