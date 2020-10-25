function px = p23(x)

[s1,s2,s3] = size(x);

if s2 < 2 && s3 < 2
   px = x;
else
   px = permute(x, [1 3 2]);
end