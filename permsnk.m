function perm = permsnk(v, k)
%PERMSNK returns all the permutations of the elements in v of length k
% example: permsnk(1:2, 2) = [1, 2; 2, 1]

if k == 1  % special case
    perm = v';
else
    temp1 = combnk(v, k);
    temp2 = combnk(v(end:-1:1), k);

    perm = sortrows([temp1; temp2]);
end
end
