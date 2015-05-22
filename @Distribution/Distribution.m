classdef Distribution < Easyset
    %% Class Distribution
    %
    %% About Distribution class
    %
    % The Distribution class defines particle size distributions as a
    % function of a characteristic variable (normally a length). It handles
    % both analytic and numerical distributions.
    %
    % The primary use of this class is within the Crystallisation Analysis
    % Toolbox (CAT).
    %
    %% Usage
    %
    % Note that the distribution is assumed to be a density function and
    % therefore boundaries of the bins are necessary to correctly calculate
    % the moments. If boundaries are not assigned, it will be assumed that
    % boundary(1) = 0 and that the remaining pivot sizes (y) lie in the
    % arithmetic mean of the remaining boundary points.
    %
    % The size vector needs to be defined. The distribution can be defined
    % as either a function handle or as a vector. The class checks the
    % inputs, and returns a vector in any case.
    %
    % The class can be called as follows:
    %
    %   dist = Distribution(y,@(x)normalpdf(x,1,0.1));
    %   or
    %   dist = Distribution(y,{'normal',1,0.1});
    %
    % to create a distribution based on the normal distribution, or the
    % properties y and F can be set separately:
    %
    %   dist = Distribution;
    %   dist.y = linspace(0,2,50);
    %   dist.F = @(x) normpdf(x,1,0.1);
    %
    % This class can be used to define multiple distributions, having their
    % own size vectors, in the following way:
    %
    %   dist(1) = Distribution(linspace(0,2),@(x)normpdf(x,1,0.1));
    %   dist(2) = Distribution(linspace(0,3),@(x)normpdf(x,2,0.5));
    %
    % Moments of Distribution objects can be calculated using the moments
    % method. See the corresponding entry.
    %
    % SEE ALSO
    % CAT, CATTube, Distribution.moments, Distribution.plot,
    % Distribution.dist2str, Distribution.data2str
    
    %% Properties
    
    % The comments before each property are what appear as help, and
    % they also appear in the GUI. Adhere to the following general
    % layout:
    %
    % Property: name
    % Short description of the property
    % Description of how the property is defined. Type, attributes etc,
    % units.
    
    properties
        
        % Property: y
        % Vector of coordinates at which distribution is defined (pivots)
        % Real, positive vector
        y = linspace(0,1,11);
        
        % Property: boundaries
        % Vector of coordinates at which distribution is defined (boundaries)
        % Real, positive vector
        boundaries
        
    end % properties
    
    properties (Dependent)
        
        % Property: F
        % Values of the particle size distribution
        % Either an anonymous function or a vector
        F = [];
        
    end % properties
    
    properties (Access=private)
        
        % Property: pF
        % Private version of F - this is where the data is stored.
        pF = [];
        
        % Property: mu
        % Mean of the distribution (if it is defined in such a
        % way).
        mu = [];
        
        % Property: sigma
        % Mean of the distribution (if it is defined in such a
        % way).
        sigma = [];
        
    end % properties
    
    %% Methods
    
    methods
        
        %% - Distribution (constructor)
        
        function O = Distribution(y,F,boundaries)
            
            % Distribution constructor
            %
            % If given, define y, F and boundaries based on inputs.
            % Otherwise, do nothing
            %
            % SEE ALSO
            % Distribution
            
            if nargin > 0 && ~isempty(y)
                O.y = y;
            end % if
            
            if nargin > 1 && ~isempty(F)
                O.F = F;
            end % if
            
            if nargin > 2 && ~isempty(boundaries)
                O.boundaries = boundaries;
            elseif nargin == 2 || (nargin==3 && isempty(boundaries))
                O.boundaries = [0 (O.y(2:end)+O.y(1:end-1))/2 3/2*O.y(end)-O.y(end-1)/2];
            end % if
            
        end % function
        
        %% Method set.y,
        
        % Call the checkPropertyValue() method
        % Along with the set() method, this function
        % captures the two ways of setting a property:
        % D.y = ...
        % set(D,'y',...)
        
        function set.y(O,value)
            
            % Distribution.set.Y
            %
            % Check input for y: a vector, all positive, increasing. Always
            % set y as a row vector
            %
            % SEE ALSO
            % Distribution
            
            % Define properties here
            O.classes.y = 'numeric';
            O.attributes.y = {'vector','real','finite','nonnegative','nondecreasing'};
            
            % Redirect to checkPropertyValue function to do checking
            O.checkPropertyValue('y',value);
            
            % If checks didn't fail, method has not exited, so do extra
            % checks
            

            O.y = value(:)';
                

            
        end % function
        
        %% Method set.boundaries
        
        % Call the checkPropertyValue() method
        % Along with the set() method, this function
        % captures the two ways of setting a property:
        % D.y = ...
        % set(D,'y',...)
        
        function set.boundaries(O,value)
            
            % Distribution.set.boundaries
            %
            % Check input for boundaries: a vector, all positive (and 0),
            % duplicates allowed. Always set boundaries as a row vector
            %
            % SEE ALSO
            % Distribution
            
            % Define properties here
            O.classes.boundaries = 'numeric';
            O.attributes.boundaries = {'vector','real','finite','nondecreasing','nonnegative'};
            
            % Redirect to checkPropertyValue function to do checking
            O.checkPropertyValue('boundaries',value);
            
            % If checks didn't fail, method has not exited, so do extra
            % checks
            
            if length(value) > 1 
                O.boundaries = value(:)';
                
                if length(O.y) ~= length(value)-1
                    O.y = (O.boundaries(1:end-1)+O.boundaries(2:end))/2;
%                     warning('Distribution:setboundaries:yAndBoundariesConsistency',...
%                         'Numel of property boundaries inconsistent with property y. Reset y as arithmetic means of boundaries.');
                end

            else
                warning('Distribution:setboundaries:yIsScalar',...
                    'Property boundaries must be a vector with at least two elements');

            end % if
            
        end % function
        
        %% - set.F
        
        function set.F(O,value)
            
            % Distribution.set.F
            %
            % Check input: vector, function handle, empty
            %
            % SEE ALSO
            % Distribution
            
            % Define properties here
            O.classes.F = {'function_handle','numeric','cell'};
            O.attributes.F = {'vector','real'};
            
            % Redirect to checkPropertyValue function to do checking
            O.checkPropertyValue('F',value);
            
            if isa(value,'function_handle')
                % Value is ok, set
                O.pF = value;
            elseif ~iscell(value) && isvector(value) || isempty(value)
                O.pF = value(:)'; %make it a row vector
            elseif iscell(value) && length(value)==3
                if strcmpi(value{1},'normal')
                    O.pF = str2func(['@(x) 1./(',data2str(value{3}),'*sqrt(2*pi))*exp(-((x-',data2str(value{2}),').^2/(2*',data2str(value{3}),'^2)))']);
                    O.mu = value{2};
                    O.sigma = value{3};
                elseif strcmpi(value{1},'lognormal')
                    O.pF = str2func(['@(x) 1./(x*',data2str(value{3}),').*exp(-((log(x)-',data2str(value{2}),').^2/(2*',data2str(value{3}),'^2)))']);
                    O.mu = value{2};
                    O.sigma = value{3};
                end
            else
                % Value is not OK - display warning
                warning('Distribution:setF0:WrongType',...
                    'F has to be a function handle, a vector or a cell of length 3');
            end % if
            
        end % function
        
        %% - get.F
        
        function Fout = get.F(O)
            
            % Distribution.get.F
            % Return F, based on what is in y.
            % If F is a function handle: calculate vector using positions
            % at y. If F is a vector, check so that its size is the same
            % as that of y
            %
            % SEE ALSO
            % Distbribution
            
            if isa(O.pF,'function_handle')
                % Function handle - calculate values
                
                Fout = O.pF(O.y);
                
            elseif isvector(O.pF)
                
                if any( size(O.pF) ~= size(O.y) )
                    warning('Distribution:getF0:WrongSize',...
                        'F is not the same size as y');
                    Fout = O.pF;
                else
                    Fout = O.pF;
                end % if else
                
            else
                Fout = [];
            end % if else
            
            % Always return a row vector
            Fout = Fout(:)';
            
        end % function
        
        %% - getFunction
        
        function fnc = getFunction(O)
            
            % Distribution.getFunction
            %
            % Return the actual function definition of the Distribution -
            % not just the values. If no function is defined, return empty
            %
            % SEE ALSO
            % Distribution
            
            if isa(O.pF,'function_handle')
                fnc = O.pF;
            else
                fnc = [];
            end % if
            
        end % function
        
        %% - moments(F,j)
        
        function Fmo = moments(O,j,icalc)
            
            % Distribution.moments
            %
            % Calculate moments from distribution/distributions over time.
            %
            % Use moments(F,j) to calculate the j'th moment of F over its
            % length.
            %
            % moments returns the indicated moment as a row vector
            %
            % To calculate moments at specific indices points, use e.g.:
            %   F.moments(3,[1 3 5])
            %
            % SEE ALSO
            % Distribution
            
            
            if nargin <= 2 && ~exist('icalc','var')
                icalc = 1:length(O);
            end
            
            % If possible, calculate moment. Otherwise do nothing
            if nargin > 1 && ~isempty(j)
                
                % Preallocate Fmo
                Fmo = zeros(size(icalc));
                
                for i = icalc
                    
                    if ~isempty(O(i).F)
                        
                        if isempty(O(1).boundaries)
                            Dy = diff([0 O(i).y]);
                        else
                            Dy = diff(O(i).boundaries);
                        end
                        
                        Fmo(icalc==i) = sum(O(i).F(:) .* Dy(:).* O(i).y(:).^j);
                        
                    end % if
                    
                end % for
                
            else
                warning('Distribution:moments:nomoment',...
                    'No type of moment was indicated');
                Fmo = [];
            end % end
            
            % Always return a row vector
            Fmo = Fmo(:)';
            
        end % function
        
        %% - disp
        
        function disp(O)
            
            % Distribution.disp
            %
            % Display the distribution in a string representation
            %
            % SEE ALSO
            % Distribution
            
            fprintf([dist2str(O) 10]);
            
        end % function
        
        %% - data2str
        
        function outstr = data2str(O)
            
            % Distribution.data2str
            %
            % Returns the distribution as a string (useful for a comparison of
            % distributions, which in general can be vectors or function
            % handles).
            %
            % This string can be used to recreate the distribution
            %
            % SEE ALSO
            % Distribution, Distribution.dist2str
            
            if isnumeric(O.pF)
                Fstr = mat2str(O.pF);
            elseif isa(O.pF,'function_handle')
                Fstr = func2str(O.pF);
                if ~isempty(O.sigma)
                    Fstr = strrep(Fstr,'value{2}',num2str(O.mu));
                    Fstr = strrep(Fstr,'value{3}',num2str(O.sigma));
                end
            end
            outstr = strcat('Distribution(',data2str(O.y),',',Fstr,',',data2str(O.boundaries),')');
            
        end % function data2str
        
        %% - dist2str
        
        function outstr = dist2str(O)
            
            % Distribution.dist2str
            %
            % Returns a string representation of the distribution object,
            % with shorthand notation describing main properties
            %
            % This string can not be used to recreate the distribution -
            % use data2str for this
            %
            % SEE ALSO
            % Distribution, Distribution.data2str
            
            % Returns a string representation of the distribution
            if isa(O.pF,'function_handle')
                type = 'Fnc';
                outstr = sprintf('%s; d_10 = %.2g, m_3 = %.2g',...
                    type,O.moments(1)/O.moments(0),O.moments(3) );
            elseif isvector(O.pF)
                type = 'Vec';
                outstr = sprintf('%s; d_10 = %.2g, m_3 = %.2g',...
                    type,O.moments(1)/O.moments(0),O.moments(3) );
            else
                outstr = 'Empty';
            end % if else
            
            
        end
        
        %% - plot
        
        function pl_handle = plot(O,Parent)
            
            % Distribution.plot
            %
            % Plots number- and volume-weighted distributions
            %
            % SEE ALSO
            % Distribution
            
            if nargin < 2 || all(isempty(Parent)) || ~any(ishandle(Parent))
                Parent = figure;
                set(Parent,'numbertitle','off','name','PSDs (overlapping)');
            end % if
            
            Fax(1) = subplot(1,2,1,'Parent',Parent);
            Fax(2) = subplot(1,2,2,'Parent',Parent);
            xlabel(Fax(1),'Mean Char. Length')
            xlabel(Fax(2),'Mean Char. Length')
            ylabel(Fax(1),'Normalized Number Distribution')
            ylabel(Fax(2),'Normalized Volume Distribution')
            
            box(Fax(1),'on');
            box(Fax(2),'on');
            
            hold(Fax(1),'all')
            hold(Fax(2),'all')
            
            pl_handle = zeros(2*length(O),1);
            
            for i = 1:length(O)
                pl_handle(2*i-1) = plot(O(i).y,O(i).F./moments(O(i),0),'Parent',Fax(1));
                pl_handle(2*i) = plot(O(i).y,O(i).F.*O(i).y.^3./moments(O(i),3),'Parent',Fax(2));
            end % for
            
            if nargout < 1
                clear pl_handle
            end % if
            
        end % function
        
        %% - isnan
        
        function no = isnan(O)
            
            % Distribution.isnan
            %
            % Always returns false
            %
            % SEE ALSO
            % Distribution
            
            no = false;
        end
        
    end % methods
    
    %% Static methods
    
    methods (Static)
        
        %% - generateCC
        
        function distCC = dist2distCC(dist,kv)
            
            % Distribution.generationCC
            %
            % Returns the distribution as it would be measured by the Coulter Counter
            %
            % SEE ALSO
            % Distribution
            
            if isa(kv,'CAT')
                kv = kv.kv;
            end
            Dy = diff(dist.boundaries);
            N = dist.F.*Dy;
            Ld = (6/pi*kv*dist.y.^3).^(1/3);
            boundariesCC = [20,20.2280000000000,20.4587000000000,20.6919000000000,20.9279000000000,21.1665000000000,21.4078000000000,21.6519000000000,21.8988000000000,22.1485000000000,22.4010000000000,22.6564000000000,22.9147000000000,23.1760000000000,23.4403000000000,23.7075000000000,23.9778000000000,24.2512000000000,24.5277000000000,24.8074000000000,25.0902000000000,25.3763000000000,25.6656000000000,25.9583000000000,26.2543000000000,26.5536000000000,26.8564000000000,27.1626000000000,27.4723000000000,27.7855000000000,28.1023000000000,28.4227000000000,28.7468000000000,29.0746000000000,29.4061000000000,29.7414000000000,30.0805000000000,30.4234000000000,30.7703000000000,31.1212000000000,31.4760000000000,31.8349000000000,32.1979000000000,32.5650000000000,32.9363000000000,33.3118000000000,33.6916000000000,34.0758000000000,34.4643000000000,34.8573000000000,35.2547000000000,35.6567000000000,36.0632000000000,36.4744000000000,36.8903000000000,37.3109000000000,37.7363000000000,38.1666000000000,38.6017000000000,39.0419000000000,39.4870000000000,39.9372000000000,40.3926000000000,40.8531000000000,41.3189000000000,41.7901000000000,42.2665000000000,42.7485000000000,43.2359000000000,43.7288000000000,44.2274000000000,44.7317000000000,45.2417000000000,45.7576000000000,46.2793000000000,46.8069000000000,47.3406000000000,47.8804000000000,48.4263000000000,48.9785000000000,49.5369000000000,50.1017000000000,50.6730000000000,51.2507000000000,51.8351000000000,52.4261000000000,53.0239000000000,53.6284000000000,54.2399000000000,54.8583000000000,55.4838000000000,56.1164000000000,56.7563000000000,57.4034000000000,58.0579000000000,58.7199000000000,59.3894000000000,60.0665000000000,60.7514000000000,61.4441000000000,62.1446000000000,62.8532000000000,63.5699000000000,64.2947000000000,65.0277000000000,65.7692000000000,66.5191000000000,67.2775000000000,68.0446000000000,68.8204000000000,69.6051000000000,70.3987000000000,71.2014000000000,72.0132000000000,72.8343000000000,73.6648000000000,74.5047000000000,75.3542000000000,76.2133000000000,77.0823000000000,77.9612000000000,78.8501000000000,79.7491000000000,80.6584000000000,81.5781000000000,82.5082000000000,83.4490000000000,84.4004000000000,85.3627000000000,86.3360000000000,87.3204000000000,88.3160000000000,89.3230000000000,90.3415000000000,91.3715000000000,92.4133000000000,93.4670000000000,94.5327000000000,95.6105000000000,96.7007000000000,97.8032000000000,98.9184000000000,100.046000000000,101.187000000000,102.341000000000,103.508000000000,104.688000000000,105.881000000000,107.089000000000,108.310000000000,109.545000000000,110.794000000000,112.057000000000,113.334000000000,114.627000000000,115.934000000000,117.255000000000,118.592000000000,119.945000000000,121.312000000000,122.695000000000,124.094000000000,125.509000000000,126.940000000000,128.388000000000,129.851000000000,131.332000000000,132.829000000000,134.344000000000,135.876000000000,137.425000000000,138.992000000000,140.577000000000,142.179000000000,143.800000000000,145.440000000000,147.098000000000,148.776000000000,150.472000000000,152.188000000000,153.923000000000,155.678000000000,157.453000000000,159.248000000000,161.064000000000,162.900000000000,164.757000000000,166.636000000000,168.536000000000,170.458000000000,172.401000000000,174.367000000000,176.355000000000,178.366000000000,180.399000000000,182.456000000000,184.537000000000,186.641000000000,188.769000000000,190.921000000000,193.098000000000,195.300000000000,197.526000000000,199.778000000000,202.056000000000,204.360000000000,206.690000000000,209.047000000000,211.430000000000,213.841000000000,216.279000000000,218.745000000000,221.239000000000,223.762000000000,226.313000000000,228.894000000000,231.503000000000,234.143000000000,236.813000000000,239.513000000000,242.244000000000,245.006000000000,247.799000000000,250.624000000000,253.482000000000,256.372000000000,259.295000000000,262.252000000000,265.242000000000,268.266000000000,271.325000000000,274.418000000000,277.547000000000,280.712000000000,283.913000000000,287.150000000000,290.424000000000,293.735000000000,297.084000000000,300.471000000000,303.897000000000,307.362000000000,310.867000000000,314.411000000000,317.996000000000,321.622000000000,325.289000000000,328.998000000000,332.749000000000,336.543000000000,340.380000000000,344.261000000000,348.186000000000,352.156000000000,356.172000000000,360.233000000000,364.340000000000,368.494000000000,372.696000000000,376.945000000000,381.243000000000,385.590000000000,389.986000000000,394.433000000000,398.930000000000,403.479000000000,408.079000000000,412.732000000000,417.438000000000,422.197000000000,427.011000000000,431.880000000000,436.804000000000,441.784000000000,446.822000000000,451.916000000000,457.069000000000,462.280000000000,467.551000000000,472.882000000000,478.274000000000,483.727000000000,489.242000000000,494.821000000000,500.462000000000,506.169000000000,511.940000000000,517.777000000000,523.680000000000,529.651000000000,535.690000000000,541.798000000000,547.976000000000,554.224000000000,560.543000000000,566.934000000000,573.398000000000,579.936000000000,586.548000000000,593.236000000000,600;];
            yCC = (boundariesCC(1:end-1)+boundariesCC(2:end))/2;
            NCC = zeros(size(yCC));
            
            for i = 1:length(boundariesCC)-1
                NCC(i) = sum(N(Ld>boundariesCC(i) & Ld<boundariesCC(i+1)));
            end
            
            yCCorg = yCC(NCC~=0);
            NCCorg = NCC(NCC~=0);NCCorg = NCCorg/sum(NCCorg);
            
            NCC = interp1(yCCorg,NCCorg,yCC);
            
            NCC(isnan(NCC)) = 0;
            
            NCC = NCC/sum(NCC.*diff(boundariesCC));
            
            distCC = Distribution(yCC,NCC,boundariesCC);
            
        end
        
        
    end
end % classdef