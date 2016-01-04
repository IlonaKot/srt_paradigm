This is my code for the Saccadic Reaction Time paradigm, as first
introduced by [Sébastien M. Crouzet](https://scrouzet.github.io/) et al.
in his paper *Crouzet, S. M., Kirchner, H., & Thorpe, S. J. (2010). Fast
saccades toward faces: face detection in just 100 ms. Journal of Vision,
10(4), 16.1–17. http://doi.org/10.1167/10.4.16*. 
I used this code to
test our setup for our work on familiar faces, *Visconti di Oleggio
Castello, M., & Gobbini, M. I. (2015). Familiar Face Detection in 180ms.
PLoS ONE, 10(8), e0136548.
http://doi.org/10.1371/journal.pone.0136548.s010*.

If you use this code, please acknowledge the original paper that introduced 
the paradigm, and share your improvements with pull requests.

# General requirements
The code requires

- Psychtoolbox 3 (the code was run with version 3.0.11)
- MATLAB (tested with version 2014b. It might work with octave, but I
  haven't tried it)
- **Eyelink Plus 1000** system—the code needs to be modified if you
  plan to use it with other eye-tracking systems.

Also, you won't find stimuli in this repository as I do not have the
rights to share them. Please contact the author of the original paper
([Sébastien M. Crouzet](https://scrouzet.github.io/)) to obtain them.

# How it works
The code could be made more user-friendly (I welcome pull requests),
however this is how it works as of now.

The structure of the folder is as follows: the main code resides in the
`code` directory; subject-specific trial-order files are under the `csv`
directory, with one folder for each subject id, for example `csv/mv00`.
In the subject-specific folder you need two txt files containing the
filenames of the stimuli corresponding to faces and objects. These
stimuli must exist in the `stim` directory. See `csv/test-before` as an
example of the directory before running `make_order_trials` (see below).

My approach was to create a modular code in which the main experiment
code reads in CSV files containing the trial order for each block and
subject, and another code creates the trial orders. The main files of 
the experiment are 

- `setupExp.m` for general setup, 
- `make_order_trials.m` to generate the CSV files of the trial order,
  and
- `srt_paradigm.m`, the code that reads in the CSV files and shows the
  experiment.

**You must be in the `code` directory to make the code run. Do not add
all the directories to the matlab path. Alternatively, you need to fix
`setupExp.m`.**

## `setupExp.m`
Here you should only change what is between lines 23–44, in particular
the distance of the subject from the screen `DIST_CM`, the width of the
screen `SCREEN_W_CM`, and the resolution and refresh rate of your system
`RESOLUTION`.

For debugging, you can also set `DEBUG` to 1 on line 24. In this way
there's no need to have the eye tracker connected and it will use mouse
position instead of eye position.

## `make_order_trials.m`
This function generate blocks of pseudo-randomized trials, making sure
that targets occur in each hemifield equally often within each block.
You are welcome to write your own code to generate these CSV files. See
below for the type of input that `srt_paradigm.m` accepts.

To generate the CSV files with this function, you need the following:

```
>> help make_order_trials
  Saccadic Reaction Time paradigm
  make_order_trials(subid, cfg) makes csv files for subject subid

  Arguments
        subid           subject id

        cfg             a structure with the following fields

           stimulitxt   a cell with the filenames of the txt files containing
                        the filenames of the stimuli. It assumes that these txt
                        files are stored under ./csv/subid/. Stimuli need to be
                        stored in ./stim/
           stimulitype  a cell containing the labels for the stimuli type, 
                        in the same order as stimulitxt 
           imagerep     (optional) number of repetitions for each image
           blocklength  (optional) specify length of the blocks. The program
                        will try to split each task into smaller blocks of
                        length blocklength, with targets balanced into
                        left/right hemifields. If it cannot do it (because
                        blocklength does not evenly divide the total number of
                        trials), it will complain and abort.

  Output
        csv files under ./csv/subid/
        a txt file under ./csv/subid/ containing the codes for each condition
```

Note that it checks that the stimuli exist under `./stim/`—better to fail 
early that during the experiment. As an example of the output, see the
files contained in `csv/test-after/`. Those where generated running
the function in the following way (again, if you do not have the stimuli
in the `stim` directory it will fail):

``` matlab
subid = 'test-after';
cfg = [];
cfg.stimulitxt = {'faces.txt', 'objects.txt'};
cfg.stimulitype = {'faces', 'objects'};
cfg.blocklength = 50;

make_order_trials(subid, cfg);
```

this generated the files in `csv/test-after`:

```
test-after
├── faces.txt
├── objects.txt
├── test-after_blocks_orig.txt
├── test-after_code_description.txt
├── test-after_tar-faces_dis-objects_1.csv
├── test-after_tar-faces_dis-objects_2.csv
├── test-after_tar-faces_dis-objects_3.csv
├── test-after_tar-faces_dis-objects_4.csv
├── test-after_tar-objects_dis-faces_1.csv
├── test-after_tar-objects_dis-faces_2.csv
├── test-after_tar-objects_dis-faces_3.csv
└── test-after_tar-objects_dis-faces_4.csv
```

The last important step is to counterbalance the order of the blocks.
You need to create a file named `subid_blocks.txt` where each line is
the filename of a block. You can look at
`csv/test-after/test-after_blocks_orig.txt` as an example of an unbalanced
block order.

The generated CSV have this structure, which can be read-in by
`srt_paradigm.m`.

```
nTrial,targType,targFn,distrType,distrFn,hemifield,code
1,faces,hommePL14.bmp,objects,voituGP19.bmp,left,1
2,faces,femmeGP02.bmp,objects,voituPL12.bmp,left,1
3,faces,femmePL09.bmp,objects,voituGP04.bmp,right,2
4,faces,femmePL19.bmp,objects,voituPL08.bmp,right,2
5,faces,hommeGP22.bmp,objects,trainPL17.bmp,right,2
6,faces,hommePL15.bmp,objects,voituPL06.bmp,left,1
7,faces,femmeGP05.bmp,objects,trainPL16.bmp,right,2
8,faces,hommePL13.bmp,objects,trainPL02.bmp,left,1
9,faces,femmePL18.bmp,objects,trainGP06.bmp,left,1
```

## `srt_paradigm.m`
This is the code that shows the stimuli to the subject. It is run as 
`srt_paradigm(subid, subnr, blocknr)`. It starts with a 9-point
calibration of the eye-tracker, followed by the experimental paradigm.
The trial starts only after the subject has maintained fixation within
the allowed range (set to 2 visual degrees from the center of the
screen; it can be modified in `setupExp.m` with the var
`MAX_DIST_FIXATION_DEG`.

When the block ends, the EDF file generated by the eye tracker is moved
to `res/edf/subid/`.

# After data collection: analysis
The output EDF can then be converted to ASCII using the EDF2ASCII
converter available on the [SR research website](http://sr-support.com/)
, and analyzed offline for saccade initiation.

I included an example parser in the directory `ana`(lysis). It *should*
work with the output generated by this code. If you make any changes to
the code of the experiment, especially to the triggers such as the
following, you might have to adapt the parser since it uses these triggers as
sentinels:

```matlab
Eyelink('Message', sprintf('Trial %d Code %s: STIM ON', itrl, ...
        output{1+itrl, 7}));
```

The parser will generate a structure whose design is inspired by the 
[Fieldtrip toolbox](http://www.fieldtriptoolbox.org):

```
s = 

         dimord: 'trl_sample_x_y_na'
            fix: {1x162 cell}
          blank: {1x162 cell}
           stim: {1x162 cell}
      trialinfo: [1x162 double]
        targets: {162x1 cell}
    distractors: {162x1 cell}
```

each of the fields `fix`, `blank` and `stim` contain the x, y position of the eye 
(and the pupil area, I believe) over time in the respective conditions: initial fixation, 
blank period, and stimulus presentation. Each element represents a single trial, whose
code is stored in `trialinfo`, with `targets` and `distractors` in the respective fields.
To sum up, for trial `i`, the code of that trial is in `s.trialinfo(i)`, the target was
`s.targets{i}` and the distractor `s.distractors{i}`; the position of the eye is stored in
`s.stim{i}`.
