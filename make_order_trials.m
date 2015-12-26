function make_order_trials(subid, cfg)
% Saccadic Reaction Time paradigm
% MAKE_ORDER_TRIALS(subid, cfg) makes csv files for subject subid
%
% Arguments
%       subid           subject id
%
%       cfg             a structure with the following fields
%
%          stimulitxt   a cell with the filenames of the txt files containing
%                       the filenames of the stimuli. It assumes that these txt
%                       files are stored under ./csv/subid/. Stimuli need to be
%                       stored in ./stim/
%          stimulitype  a cell containing the labels for the stimuli type, 
%                       in the same order as stimulitxt 
%          imagerep     (optional) number of repetitions for each image
%          blocklength  (optional) specify length of the blocks. The program
%                       will try to split each task into smaller blocks of
%                       length blocklength, with targets balanced into
%                       left/right hemifields. If it cannot do it (because
%                       blocklength does not evenly divide the total number of
%                       trials), it will complain and abort.
%
% Output
%       csv files under ./csv/subid/
%       a txt file under ./csv/subid/ containing the codes for each condition

% MVdOC Jan 15

if ~isfield(cfg, 'stimulitxt')
    error(['Please provide a cell in cfg.stimulitxt with the filenames', ...
          ' of the txt containing the stimuli']);
end
if ~isfield(cfg, 'stimulitype')
    error('Please provide a cell in cfg.stimulitype with the stimuli type');
end
if ~isfield(cfg, 'imagerep')
    cfg.imagerep = 1;
    warning('cfg.imagerep not specified, assuming imagerep = 1');
end
if ~isfield(cfg, 'blocklength')
    cfg.blocklength = -1;
    warning('cfg.blocklength not specified, blocks will have full length')
end

stimulitxt = cfg.stimulitxt;
stimulitype = cfg.stimulitype;
imagerep = cfg.imagerep;
blocklength = cfg.blocklength;

% assertions on cfg fields
assert(length(stimulitxt) == length(stimulitype));

% run setup with variables
setupExp;

global CSVDIR STIMDIR
SUBJDIR = fullfile(CSVDIR, subid);

stimulitxt = fullfile(SUBJDIR, stimulitxt);

% Output is txt file with these columns
% nTrial, targType, targFn, distrType, distrFn, hemifield, code
header = {'nTrial', 'targType', 'targFn', 'distrType', 'distrFn', ...
          'hemifield', 'code'};
NTRLCOL = 1;
TARGCOL = 2;
TARGFNCOL = 3;
DISTCOL = 4;
DISTFNCOL = 5;
HEMIFCOL = 6;
CODECOL = 7;

% get stimuli name
stimuli = cell(size(stimulitxt));
n_type_stimuli = length(stimuli);

for i = 1:n_type_stimuli
   f = fopen(stimulitxt{i});
   temp = textscan(f, '%s');
   stimuli{i} = temp{1};
   fclose(f);
end

% check we have the same number of stimuli for each type
comb_type_stimuli = combnk(1:n_type_stimuli, 2);
for i = 1:nchoosek(n_type_stimuli, 2);
    assert(length(stimuli{comb_type_stimuli(i, 1)}) == ...
           length(stimuli{comb_type_stimuli(i, 2)}));
end

% check the stimuli exist, if not complain
n_stimuli = length(stimuli{1});
for i = 1:n_type_stimuli
    for j = 1:n_stimuli
        if ~exist(fullfile(STIMDIR, stimuli{i}{j}), 'file')
            error('File %s does not exist!', fullfile(STIMDIR, stimuli{i}{j}));
        end
    end
end

% now we need to do some math...
tasks_num = permsnk(1:n_type_stimuli, 2);  % we'll be useful later
tasks = stimulitype(tasks_num);  % all pairwise combinations of stimulitype
n_tasks = length(tasks);
n_trials_task = imagerep * n_stimuli * 2;  % 2 is for left/right hemifield

% check we can divide the trials evenly into blocks...if not, complain
if rem(n_trials_task, blocklength) ~= 0 && blocklength ~= -1
    error(['Cannot divide %d trials into blocks of %d trials;', ...
           ' change settings in the cfg file'], n_trials_task, blocklength);
end

task_codes = [1 : 2 : 2*n_tasks;  % left hemifield
              2 : 2 : 2*n_tasks]; % right hemifield

% save block filenames
block_fns = cell([max(n_tasks, n_tasks*n_trials_task/blocklength), 1]);
iblock = 1;

% now we loop for each task
ncol = length(header);
for itask = 1:n_tasks
    % get target and distractor type for this target
    targ_type = tasks{itask, 1};
    targ_type_num = tasks_num(itask, 1);

    dist_type = tasks{itask, 2};
    dist_type_num = tasks_num(itask, 2);

    % we will randomize each pair of stimuli, so that target and distractors
    % occur randomly paired, then we will randomize left/right hemifield
    %
    % left hemifield
    block_left = cell([n_trials_task/2, ncol]);  % we'll add trlnumber later
    % populate target and distractor type
    block_left(:, TARGCOL) = repmat({targ_type}, [n_trials_task/2, 1]);
    block_left(:, DISTCOL) = repmat({dist_type}, [n_trials_task/2, 1]);

    % populate target and distractor filenames
    rand_targfn = multi_randperm(n_stimuli, imagerep);
    rand_distfn = multi_randperm(n_stimuli, imagerep);
    block_left(:, TARGFNCOL) = stimuli{targ_type_num}(rand_targfn);
    block_left(:, DISTFNCOL) = stimuli{dist_type_num}(rand_distfn);

    % populate hemifield and code columns
    block_left(:, HEMIFCOL) = repmat({'left'}, [n_trials_task/2, 1]);
    block_left(:, CODECOL) = repmat({task_codes(1, itask)}, ...
        [n_trials_task/2, 1]);

    % right hemifield
    block_right = cell([n_trials_task/2, ncol]);  % we'll add trlnumber later
    % populate target and distractor type
    block_right(:, TARGCOL) = repmat({targ_type}, [n_trials_task/2, 1]);
    block_right(:, DISTCOL) = repmat({dist_type}, [n_trials_task/2, 1]);

    % populate target and distractor filenames
    rand_targfn = multi_randperm(n_stimuli, imagerep);
    rand_distfn = multi_randperm(n_stimuli, imagerep);
    block_right(:, TARGFNCOL) = stimuli{targ_type_num}(rand_targfn);
    block_right(:, DISTFNCOL) = stimuli{dist_type_num}(rand_distfn);

    % populate hemifield and code columns
    block_right(:, HEMIFCOL) = repmat({'right'}, [n_trials_task/2, 1]);
    block_right(:, CODECOL) = repmat({task_codes(2, itask)}, [n_trials_task/2, 1]);

    % shall we divide into smaller blocks?
    if blocklength == -1  % no
       % add all together
       block = [block_left; block_right];

       % randomize order of trials
       block = block(randperm(n_trials_task), :);
       block(:, NTRLCOL) = num2cell(1:n_trials_task)';
       fnout = sprintf('%s_tar-%s_dis-%s_%d.csv', subid, ...
                       targ_type, dist_type, 1);
       % save block fn
       block_fns{iblock} = fnout;
       iblock = iblock + 1;

       fnout = fullfile(SUBJDIR, fnout);
       cell2csv(fnout, [header; block], ',');

    else  % we already checked it's possible
       n_small_blocks = n_trials_task/blocklength;
       idx = 0 : blocklength/2 : n_trials_task/2;
       for i = 1:n_small_blocks
          % half of the trials in the left hemifield, half in the right
          block_out = [block_left(idx(i)+1:idx(i+1), :);
                       block_right(idx(i)+1:idx(i+1), :)];

          % randomize order of trials
          block_out = block_out(randperm(blocklength), :);

          % save
          block_out(:, NTRLCOL) = num2cell(1:blocklength);
          fnout = sprintf('%s_tar-%s_dis-%s_%d.csv', subid, ...
              targ_type, dist_type, i);
          % save block fn
          block_fns{iblock} = fnout;
          iblock = iblock + 1;

          fnout = fullfile(SUBJDIR, fnout);
          cell2csv(fnout, [header; block_out], ',');
       end
    end
end

% save block fn
fnout = sprintf('%s_blocks_orig.txt', subid);
fnout = fullfile(SUBJDIR, fnout);
cell2csv(fnout, block_fns);

% save a txt file with the description of the codes
% e.g.,
% Target  Distractor  Hemifield   Code
% F       V           L           1
% F       V           R           2
% V       F           L           3
% V       F           R           4

header_descr = {'Target', 'Distractor', 'Hemifield', 'Code'};
descr = [repmat(tasks, [2, 1]), ...
         [repmat({'Left'}, [n_tasks, 1]); repmat({'Right'}, [n_tasks, 1])], ...
         num2cell([task_codes(1, :)'; task_codes(2, :)'])];
descr = sortrows(descr, 4);

fnout = sprintf('%s_code_description.txt', subid);
fnout = fullfile(SUBJDIR, fnout);
cell2csv(fnout, [header_descr; descr], ',');
