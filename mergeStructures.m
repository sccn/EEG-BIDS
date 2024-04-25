function ssMerged = mergeStructures( ssDest, ssSource )
    % mergeStructures selectively create and update fields in ssDest with those in ssSource, recursively
    
    % Merge tree-like structures in much the same way as files are
    % copied to destination folders, overwriting values where they exist.
    % 
    % Arrays of structures:
    %  ssInto and ssFrom may be struct arrays of the same size.
    %  Each (scalar) element of the source array is
    %  merged with its corresponding element in the destination.
    %
    %  Empty fields:
    %    Empty fields in a scalar (size 1-by-1) source overwrite destination.  
    %    Empty fields in an array source DO NOT overwrite destination;
    %    this makes it easier to update just a few elements of an array.
    % credit: https://www.mathworks.com/matlabcentral/fileexchange/131718-mergestructures-merge-or-concatenate-nested-structures?s_tid=mwa_osa_a

    if  ~isstruct( ssDest ) || ~isstruct( ssSource )     
        error('mergeFieldeRecurse:paramsNotStructures', ...
              'mergeFieldsRecurse() expects structures as inputs')        
    end

    % modification - Dung Truong 2024
    if isempty(ssDest) && ~isempty(ssSource)
        ssMerged = ssSource;
    elseif isempty(ssSource) && ~isempty(ssDest)
        ssMerged = ssDest;
    else
        
    if  ~all( size( ssDest ) == size( ssSource ) )     
        error('mergeFieldeRecurse:parameterSizesInequal', ...
              'mergeFieldsRecurse(): array structures must have equal sizes')        
    end
    
    ssMerged = ssDest;
    
    % loop over each element in struct arrays
    nns = numel( ssMerged );
    for ns = 1:nns
    
        f = fieldnames(ssSource);
        % loop over fields in source
        for nf = 1:length(f)
            fieldName = f{nf};

            % copy/merge field from ssSource into ssDest.
            % Overwite current values in ssMerged.
            % Creates new field in ssMerged as required.
            % Recurse if source field is a structure.
            if isa( ssSource(ns).(fieldName), 'struct')
                % source field is a structure
                if ~isfield( ssMerged(ns), fieldName)
                    % New field in destination. Do a simple copy   
                    ssMerged(ns).(fieldName) = ssSource(ns).(fieldName);
                else
                    % recurse for nested structures
                    ssM = mergeStructures( ...
                              ssMerged(ns).(fieldName), ...
                              ssSource(ns).(fieldName) );
                    ssMerged(ns).(fieldName) = ssM;
                end
            else
                % source is a value, not a structure.
                if nns > 1 && isempty( ssSource(ns).(fieldName) )
                    % don't overwrite values in arrays with []    
                else 
                    % assign/overwrite new value to current field
                    ssMerged(ns).(fieldName) = ssSource(ns).(fieldName);
                end
            end 
        end % loop over nf fields in source
    end % loop over ns elements in array of structure
    end
end % function mergeNestedStructures()
