function out = multi_randperm(n, m)
% MULTI_RANDPERM returns a random permutation of 1:n repeated m times.
%
% example:
% >> rng(1)  % for reproducibility of the example
% >> multi_randperm(3, 2)
%
% ans =
%
%      3     1     2     2     3     1

out = zeros([1, n*m]);
idx = 0 : n : n*m;
for i = 1:m
    out(idx(i)+1 : idx(i+1)) = randperm(n);
end

% randomize at the end also
out = out(randperm(n*m));
end

