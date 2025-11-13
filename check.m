function [ICind,FCind,Check] = check(FCind,ICind)

% Check that the first sample is an IC
if ~isempty(FCind) && ICind(1) > FCind(1)
    FCind(1) = [];
end

% Adjust the length
n = min(length(ICind), length(FCind));
ICind = ICind(1:n);
FCind = FCind(1:n);

% Check the alternation between ICs and FCs
valid_pairs = ICind < FCind;
ICind = ICind(valid_pairs);
FCind = FCind(valid_pairs);

% Create flag
if valid_pairs
    Check = 1;
else
    Check = 0;
end
end