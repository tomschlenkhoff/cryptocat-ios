# General Formatting

Please have a look at the existing source code before you start coding.
Some random rules that come to my mind :

- Maximum line length is 100 characters
- Use 2 spaces to indent, no tabs
- Always use curly braces with If statements :

Do this :
`
if (foo) {
  [self bar];
}
[self widget];
`

Not this :
`
if (foo)
  [self bar];
[self widget];
`

Exception, for a 1-line quick return in a method :  
`
- (NSString *)myMethod:(NSString *)aString {
  if (aString==nil) return nil;
  
  // the method implementation here …
}
`

# Code Organization

- Always init/dealloc at the beginning of your class implementation
- Always declare private @properties by default (in the class continuation, in the .m), unless they really need to be public (in the .h file).

# Code Separators

- Before @interface, @implementation, @protocol, add :
`
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
`

- Before each method, add :
`
////////////////////////////////////////////////////////////////////////////////////////////////////
`