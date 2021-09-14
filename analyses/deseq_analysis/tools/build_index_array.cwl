cwlVersion: v1.0
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
  test_maximum: {type: 'int?', doc: "Max number to use for testing"}

outputs:
  index_array:
    type: int[]

expression:
  "${
    var start = 1;
    var end = inputs.index_max_file.contents.split('\\n')[0];
    if (inputs.test_maximum) {
      end = inputs.test_maximum
    }
    var step = 1;
    var index_array = [];
    while (end >= start) {
      index_array.push(start);
      start += step;
      }
    return {'index_array': index_array};
  }"
