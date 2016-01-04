function data = save_block_data(fid)
isample = 1;
data = double([]);
% go to next line and start collecting data
line = fgetl(fid);
words = textscan(line, '%s');
% go ahead collecting until we don't get another MSG
while ~strcmp(words{1}(1), 'MSG')
    % if the line contains one of those weird messages,
    % skip the line and go to the next
    if strcmp(words{1}(1), 'SSACC') || ...
            strcmp(words{1}(1), 'ESACC') || ...
            strcmp(words{1}(1), 'SFIX') || ...
            strcmp(words{1}(1), 'EFIX') || ...
            strcmp(words{1}(1), 'SBLINK') || ...
            strcmp(words{1}(1), 'EBLINK')
        line = fgetl(fid);
        words = textscan(line, '%s');
        continue
    end
    D = textscan(line, '%*f %.1f %.1f %.1f');
    % if blink or missing data, return NaNs
    if all(cellfun('isempty', D))
        data(isample, :) = [NaN NaN NaN];
    else
        data(isample, :) = [D{:}];
    end
    isample = isample + 1;
    line = fgetl(fid);
    words = textscan(line, '%s');
end
end % function save_block_data