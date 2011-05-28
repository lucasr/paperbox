// This is to be used by coffee script files as a way
// to export symbols to global scope. We could use window
// directly but the semantics is more obvious if we use
// a more app-specific and readable variable names.

// Namespace for classes specific to PaperBox
var PaperBox = {};

// Namespace for all global object instances. Should not be
// abused. Ideally, only expose the app instance and few other
// app-wise objects.
var Global = {};
