function envelope = build_response_envelope(raw_response)
%BUILD_RESPONSE_ENVELOPE Cumulative maximum of absolute response by column.
validateattributes(raw_response, {'numeric'}, {'2d','real'});
envelope = cummax(abs(raw_response), 1);
end
