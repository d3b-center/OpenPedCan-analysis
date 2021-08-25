cwlVersion: v1.2
class: ExpressionTool
id: build_index_array
doc: "Turn a file with the maximum number of indices into an array of ints"
requirements:
  - class: InlineJavascriptRequirement

inputs:
  index_max_file:
    type: 'File'
    doc: "File with last number of array"
    inputBinding:
      loadContents: true

outputs:
  index_array:
    type: int[]

expression:
  "${
    var start = 1;
    var end = inputs.index_max_file.contents.split('\\n')[0];
    var step = 1;
    var index_array = function(start, end, step) {
      var index_array = [];
      while (end >= start) {
        range.push(start);
        start += step;
      }
    }
    return {'index_array': index_array};
  }"
