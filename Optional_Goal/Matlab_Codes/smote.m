function [X,C,Xn,Cn] = smote(X, N, k, options)
    arguments
        X (:,:) % Observation Matrix
        N (:,1) double {mustBeNonnegative} = 1 % Amount of synthesization
        k (:,1) double {mustBePositive,mustBeInteger} = 5 % Number of nearest neighbors to consider
        options.Class (:,1) {mustBeSameSize(options.Class,X)} % Class vector: Determines the class of each observation
        options.SynthObs (:,1) {mustBeSameSize(options.SynthObs,X)} % Synthesization vector. Determines how many times each observation is used as a base for synthesization
    end
    
    % Handle optional Class vector
    if isfield(options,'Class')
        C = options.Class;
    else
        C = ones(size(X,1),1); % If no Class vector is given, default all observations to the same class: [1]
    end
    uC = unique(C); % Class list
    nC = groupcounts(C); % Number of observations of each class
    
    % Handle N - must have one number for each class
    if isempty(N) % Do balancing if N is empty
        if numel(uC)<2 % Class vector must contain at least two classes to balance
            error('Class vector must contain at least 2 classes to balance.');
        end
        N = max(nC)./nC-1; % Calculate over-sampling percentage for each class to attain equal number of observations as majority class
    elseif isscalar(N)
        N = repmat(N,numel(uC),1); 
    elseif ~isvector(N) || numel(N)~=numel(uC)
        error('N must either be empty, a scalar, or a vector with same number of elements as unique classes.');
    end
    
    % Handle k - must have one number for each class
    if isscalar(k)
        k = repmat(k,numel(uC),1); 
    elseif ~isvector(k) || numel(k)~=numel(uC)
        error('k must either be a scalar or a vector with same number of elements as unique classes.');
    end
    
    % Decide on how many of each observation (in case of non-integer,
    % 'extras' will be chosen at random). Vector J determines how many of
    % each observation is used as a base for synthesization.
    if isfield(options,'SynthObs')
        J = options.SynthObs;
    else
        J = nan(size(X,1),1); % Synthesization vector
        for ii=1:numel(uC) % Iterate through the classes
            iC = find(C==uC(ii));
            P = randperm(nC(ii),round(rem(N(ii),1)*nC(ii))); % Randomly pick indexes of 'extras'
            J(iC) = ones(nC(ii),1)*floor(N(ii)); % First distribute evenly
            J(iC(P)) = J(iC(P))+1; % Then assign the 'extras'
        end
    end
    
    % Synthesize observations
    Xn = []; % TODO: Consider pre-allocating memory
    Cn = []; % TODO: Consider pre-allocating memory
    for ii=1:numel(uC)
        iC = C==uC(ii);
        if sum(J(iC))>0 % Skip synthesization attempt if no observations are synthesized for this class (for speed)
            Xnn = simpleSMOTE(X(iC,:),J(iC),k(ii));
            Xn = [Xn;Xnn]; % TODO: Consider pre-allocating memory
            Cn = [Cn;repmat(uC(ii),size(Xnn,1),1)]; % TODO: Consider pre-allocating memory
        end
    end
    % Set output
    X = [X;Xn];
    C = [C;Cn];
end
% This is where the magic happens ;-)
%   X : Observational matrix (rows are observations, columns are variables)
%   J : Synthesization vector. It has the same length as the number of
%       observations (rows) in X. J determines how many times each 
%       observation is used as a base for synthesization.
%   k : Number of nearest neighbors to consider when synthesizing.
function Xn = simpleSMOTE(X,J,k)
    [idx, ~] = knnsearch(X,X,'k',k+1); % Find nearest neighbors (add one to the number of neighbors to find, as observations are their own nearest neighbor)
    Xn = nan(sum(J),size(X,2)); % Pre-allocate memory for synthesized observations
    % Iterate through observations to create to synthesize new observations
    for ii=1:numel(J)
        P = randperm(k,J(ii))+1; % Randomize nearest neighbor pick (never pick first nearest neighbor as this is the observation itself)
        for jj=1:J(ii)
            x = X(idx(ii,1),:); % Observation
            xk = X(idx(ii,P(jj)),:); % Nearest neighbor
            Xn(sum(J(1:ii-1))+jj,:) = (xk-x)*rand+x; % Synthesize observation
        end
    end
end
% Argument validation
function mustBeSameSize(a,b)
    if ~isequal(size(a,1),size(b,1))
        error('Must have the same number of elements as number of observations (rows) in X.');
    end
end