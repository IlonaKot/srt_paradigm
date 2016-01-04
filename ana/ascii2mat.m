function ascii2mat(dirin, fnin, dirout)
% ASCII2MAT converts the ascii file created from EDF2ASCII to a matlab
% structure. Reads fnin contained in dirin and saves it in dirout.
%
% Example:
% ascii2mat('/data/ascii/', 'myascii.asc', '/data/mat/');

fnout = strrep(fnin, '.asc', '.mat');
fnin = fullfile(dirin, fnin);
fnout = fullfile(dirout, fnout);

if exist(fnout, 'file')
    warning('Output file %s already exists, skipping it', fnout);
    return
end

fprintf('Opening file %s\n\n', fnin);
fid = fopen(fnin, 'r');
line = fgetl(fid);

trialinfo = [];
count = 1;

while ischar(line)
    if mod(count, 100) == 0
        fprintf('%d ', count);
        if mod(count, 1000) == 0
            fprintf('\n');
        end
    end
    % if line is empty, skip to the next one
    if isempty(line)
        line = fgetl(fid);
        continue
    end
    words = textscan(line, '%s');
    % if line starts with MSG, then go on
    if strcmp(words{1}(1), 'MSG')
        % if contains Trial, then this is what we need
        if strcmp(words{1}(3), 'Trial')
            C = textscan(line, 'MSG %*d Trial %d Code %d: %s %s');
            itrl = C{1};
            if strcmp(C{3}, 'START')
                C = textscan(line, 'MSG %*d Trial %d Code %d: %*s %*s %s %*s %s');
                targets(itrl) = C{3};
                distractors(itrl) = C{4};
            end
            trialinfo(itrl) = C{2};
            % if it's FIXATION, start to save data
            if strcmp(C{3}, 'FIXATION')
                data_fixation{itrl} = save_block_data(fid);
            % if it's BLANK2, save data
            elseif strcmp(C{3}, 'BLANK2')
                data_blank{itrl} = save_block_data(fid);
            % if it's STIM, save data
            elseif strcmp(C{3}, 'STIM')
                data_stim{itrl} = save_block_data(fid);
            end
        end
    end
    line = fgetl(fid);
    count = count + 1;
end
fclose(fid);

output.dimord = 'trl_sample_x_y_na';
output.fix = data_fixation;
output.blank = data_blank;
output.stim = data_stim;
output.trialinfo = trialinfo;
output.targets = targets';
output.distractors = distractors';

fprintf('\n\nSaving to %s\n', fnout);
save(fnout, '-struct', 'output');
end % function asc2mat
