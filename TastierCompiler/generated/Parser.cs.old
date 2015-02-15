
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;

using Symbol = System.Tuple<string, int, int, int, int>;
using Instruction = System.Tuple<string,string>;
using StackAddress = System.Tuple<int, int>;

namespace Tastier {



public class Parser {
	public const int _EOF = 0;
	public const int _ident = 1;
	public const int _number = 2;
	public const int _stringValues = 3;
	public const int maxT = 54;

	const bool T = true;
	const bool x = false;
	const int minErrDist = 2;

	public Scanner scanner;
	public Errors  errors;

	public Token t;    // last recognized token
	public Token la;   // lookahead token
	int errDist = minErrDist;

enum TastierType : int
{   // types for variables
  Undefined,
  Integer,
  Boolean,
  String
};

enum TastierKind : int
{  // kinds of symbol
  Var,
  Proc,
  Constant,
  RecordDecl, // template for the record
  RecordVar,  // variable in a record
  RecordInst, // a record instance
  Array,	  // an array
  Array_Size, // size of the array.
  String_Size // size of the string
};

/*
You'll notice some type aliases, such as the one just below, are commented
out. This is because C# only allows using-alias-directives outside of a
class, while class-inheritance directives are allowed inside. So the
snippet immediately below is illegal in here. To complicate matters
further, the C# runtime does not properly handle class-inheritance
directives for Tuples (it forces you to write some useless methods). For
these reasons, the type aliases which alias Tuples can be found in
Parser.frame, but they're documented in this file, with the rest.
*/

//using Symbol = System.Tuple<string, int, int, int, int>;

/*
A Symbol is a name with a type and a kind. The first int in the
tuple is the kind, and the second int is the type. We'll use these to
represent declared names in the program.

For each Symbol which is a variable, we have to allocate some storage, so
the variable lives at some address in memory. The address of a variable on
the stack at runtime has two components. The first component is which
stack frame it's in, relative to the current procedure. If the variable is
declared in the procedure that's currently executing, then it will be in
that procedure's stack frame. If it's declared in the procedure that
called the currently active one, then it'll be in the caller's stack
frame, and so on. The first component is the offset that says how many
frames up the chain of procedure calls to look for the variable. The
second component is simply the location of the variable in the stack frame
where it lives.

The third int in the symbol is the stack frame on which the variable
lives, and the fourth int is the index in that stack frame. Since
variables which are declared in the global scope aren't inside any
function, they don't have a stack frame to go into. In this compiler, our
convention is to put these variables at an address in the data memory. If
the variable was declared in the global scope, the fourth field in the
Symbol will be zero, and we know that the next field is an address in
global memory, not on the stack.

Procedures, on the other hand, are just sets of instructions. A procedure
is not data, so it isn't stored on the stack or in memory, but is just a
particular part of the list of instructions in the program being run. If
the symbol is the name of a procedure, we'll store a -1 in the address
field (5).

When the program is being run, the code will be loaded into the machine's
instruction memory, and the procedure will have an address there. However,
it's easier for us to just give the procedure a unique label, instead of
remembering what address it lives at. The assembler will take care of
converting the label into an address when it encounters a JMP, FJMP or
CALL instruction with that label as a target.

To summarize:
* Symbol.Item1 -> name
* Symbol.Item2 -> kind
* Symbol.Item3 -> type
* Symbol.Item4 -> stack frame pointer
* Symbol.Item5 -> variable's address in the stack frame pointed to by
Item4, -1 if procedure
*/

class Scope : Stack<Symbol> {}

/*
A scope contains a stack of symbol definitions. Every time we come across
a new local variable declaration, we can just push it onto the stack. We'll
use the position of the variable in the stack to represent its address in
the stack frame of the procedure in which it is defined. In other words, the
variable at the bottom of the stack goes at location 0 in the stack frame,
the next variable at location 1, and so on.
*/

//using Instruction = Tuple<string, string>;
class Program : List<Instruction> {}

/*
A program is just a list of instructions. When the program is loaded into
the machine's instruction memory, the instructions will be laid out in the
same order that they appear in this list. Because of this, we can use the
location of an instruction in the list as its address in instruction memory.
Labels are just names for particular locations in the list of instructions
that make up the program.

The first component of all instructions is a label, which can be empty.
The second component is the actual instruction itself.

To summarize:
* Instruction.Item1 -> label
* Instruction.Item2 -> the actual instruction, as a string
*/

Stack<Scope> openScopes = new Stack<Scope>();
Scope externalDeclarations = new Scope();

/*
Every time we encounter a new procedure declaration in the program, we want
to make sure that expressions inside the procedure see all of the variables
that were in scope at the point where the procedure was defined. We also
want to make sure that expressions outside the procedure do not see the
procedure's local variables. Every time we encounter a procedure, we'll push
a new scope on the stack of open scopes. When the procedure ends, we can pop
it off and continue, knowing that the local variables defined in the
procedure cannot be seen outside, since we've popped the scope which
contains them off the stack.
*/

Program program = new Program();
Program header = new Program();

Stack<string> openProcedureDeclarations = new Stack<string>();

/*
In order to implement the "shadowing" of global procedures by local procedures
properly, we need to generate a label for local procedures that is different
from the label given to procedures of the same name in outer scopes. See the
test case program "procedure-label-shadowing.TAS" for an example of why this
is important. In order to make labels unique, when we encounter a non-global
procedure declaration called "foo" (for example), we'll give it the label
"enclosingProcedureName$foo" for all enclosing procedures. So if it's at
nesting level 2, it'll get the label "outermost$nextoutermost$foo". Let's
make a function that does this label generation given the set of open
procedures which enclose some new procedure name.
*/

string generateProcedureName(string name)
{
  if (openProcedureDeclarations.Count == 0)
  {
    return name;
  }
  else
  {
    string temp = name;
    foreach (string s in openProcedureDeclarations)
    {
      temp = s + "$" + temp;
    }
    return temp;
  }
}

/*
We also need a function that figures out, when we call a procedure from some
scope, what label to call. This is where we actually implement the shadowing;
the innermost procedure with that name should be called, so we have to figure
out what the label for that procedure is.
*/

string getLabelForProcedureName(int lexicalLevelDifference, string name)
{
  /*
  We want to skip <lexicalLevelDifference> labels backwards, but compose
  a label that incorporates the names of all the enclosing procedures up
  to that point. A lexical level difference of zero indicates a procedure
  defined in the current scope; a difference of 1 indicates a procedure
  defined in the enclosing scope, and so on.
  */
  int numOpenProcedures = openProcedureDeclarations.Count;
  int numNamesToUse = (numOpenProcedures - lexicalLevelDifference);
  string theLabel = name;

  /*
  We need to concatenate the first <numNamesToUse> labels with a "$" to
  get the name of the label we need to call.
  */

  var names = openProcedureDeclarations.Take(numNamesToUse);

  foreach (string s in names) {
    theLabel = s + "$" + theLabel;
  }

  return theLabel;
}

Stack<string> openLabels = new Stack<string>();
int labelSeed = 0;

string generateLabel()
{
  return "L$"+labelSeed++;
}

/*
Sometimes, we need to jump over a block of code which we're about to
generate (for example, at the start of a loop, if the test fails, we have
to jump to the end of the loop). Because it hasn't been generated yet, we
don't know how long it will be (in the case of the loop, we don't know how
many instructions will be in the loop body until we actually generate the
code, and count them). In this case, we can make up a new label for "the
end of the loop" and emit a jump to that label. When we get to the end of
the loop, we can put the label in, so that the jump will go to the
labelled location. Since we can have loops within loops, we need to keep
track of which label is the one that we are currently trying to jump to,
and we need to make sure they go in the right order. We'll use a stack to
store the labels for all of the forward jumps which are active. Every time
we need to do a forward jump, we'll generate a label, emit a jump to that
label, and push it on the stack. When we get to the end of the loop, we'll
put the label in, and pop it off the stack.
*/

Symbol _lookup(Scope scope, string name)
{
  foreach (Symbol s in scope)
  {
    if (s.Item1 == name)
    {
      return s;
    }
  }
  return null;
}

Symbol lookup(Stack<Scope> scopes, string name)
{
  int stackFrameOffset = 0;
  int variableOffset = 0;
  foreach (Scope scope in scopes)
  {
    foreach (Symbol s in scope)
    {
      if (s.Item1 == name)
      {
        /* Print the current symbol being
        looked up*/
        printSymbol(s);
        return s;
      }
      else
      {
        variableOffset += 1;
      }
    }
    stackFrameOffset += 1;
    variableOffset = 0;
  }
  return null; // if the name wasn't found in any open scopes.
}

/*
Print the symbols and their attributes passed in
to the lookup() function.
*/
void printSymbol(Symbol theSymbol)
{
	  // temp strings for the symbol's type and kind
	  // as there are multiple values that they can have.
	  string kind = "";
	  string type = "";

	/* 	if item2 is a 0, then it is a variable, otherwise
		it is a procedure. 
	*/
	  if(theSymbol.Item2 == 0)
		kind = "Variable";
	  else if(theSymbol.Item2 == 1)
		kind = "Procedure";
	  else if(theSymbol.Item2 == 2)
		kind = "Constant";
	  else if(theSymbol.Item2 == 3)
		kind = "RecordDecl";
	  else if(theSymbol.Item2 == 4)
		kind = "RecordVar";
	  else if(theSymbol.Item2 == 5)
		kind = "RecordInst";
	  else if(theSymbol.Item2 == 6)
		kind = "Array";
	  else if(theSymbol.Item2 == 7)
		kind = "Array_Size";
	  else kind = "String_Size";

	  /* if item2 is a 1, then it is a int, else it is a
	  it is a void  otherwise I print out Item3. */
	  if( theSymbol.Item3 == 1)
		type = "Integer";
	  else if (theSymbol.Item3 == 0)
		type = "Undefined";
	  else if (theSymbol.Item3 == 2)
		type = "Boolean";
	  else // This should be a boolean.
		type = "String";

	  // Print out the contents of that symbol
	  System.Console.WriteLine("Name: "+theSymbol.Item1
								  +", Kind: "+kind
									  +", type: "+type
										  +", stack frame: "+theSymbol.Item4
											+", stack frame index: "+theSymbol.Item5);
}

/*
This function checks to see if a symbol already exists in the
symbol table. If it is not in the symbol table, then the function
prints out to the console that it is not, and the same for when it
is in the table.
I check to see if the symbol is in the table by using the lookup()
function that was already written in the code.
*/
void check(string name, int procOrVar)
{
  /*
  Searches the symbol table for the current name
  of the symbol
  */
  Symbol tempS = lookup(openScopes, name);
  if(procOrVar == 1)
  {
    // if we have not yet found a procedure nor a record nor a constant
    if( (encounteredProcedure == false)&&(encounteredRecord == false)&&(encounteredConstant == false) )
    {
      // Print out the name of the new global variable
      System.Console.WriteLine("Declaration of new Global variable: " + name );
      //printSymbol(tempS);
    }
    /* Otherwise we have found a procedure already
    and the symbol is a local variable.*/
    else
    {
      // print out the variable.
      System.Console.WriteLine("Declaration of new variable: " + name );
      //printSymbol(tempS);
    }
  }
  // Otherwise we found a procedure
  else
  {
    // say that we found a procedure
    encounteredProcedure = true;
    // And print out the name of that new procedure
    System.Console.WriteLine("Declaration of new procedure: " + name );
    printSymbol(tempS);
  }

}
	/* 
		boolean to say whether or not a procedure
		has been already found. This is used in order
		to see if any variables declared are global variables.
	*/
bool encounteredProcedure = false;
bool encounteredConstant = false;
bool encounteredRecord = false;
bool procReturn = false;
//bool isString = false;

//int //factorFlag = 0;

int returnLocation = 4094;
//int stringLocation = 4088;
int paramLocation = 4085;
// pointing to the location of the next
// free location in memory
int stringIndex = 4070;
//int //lastAddress = 4070;
int stringSize = 0;

// A list that contains all the constants to be added.
List <Symbol> constantsList = new List <Symbol> ();

// A list of the record templates and the record instances
List<List<Symbol>> recordListTemplate = new List <List<Symbol>> ();
List<List<Symbol>> recordInstances = new List <List<Symbol>> ();

// A list of instructions to see if there is an array with that name
//List<List<Instruction>> arrayLookUp = new List <List<Instruction>>();

// A list that contains the instructions to load from a procedure return.
//List<Tuple<Instruction, string>> returnInst = new List <Tuple<Instruction, string>>();

// A list that contains a template for procedure parameters.
List<List<Symbol>> procParams = new List<List<Symbol>>();

// A list that contains the name and size of each string
List<Tuple<string,int>> stringSizes = new List <Tuple<string, int>>();

/*
	You may notice that when we use a LoadG or StoG instruction, we add 3 to
	the address of the item being loaded or stored. This is because the
	control and status registers of the machine are mapped in at addresses 0,
	1, and 2 in data memory, so we cannot use those locations for storing
	variables. If you want to load rtp, rbp, or rpc onto the stack to
	manipulate them, you can LoadG and StoG to those locations.
*/

/*--------------------------------------------------------------------------*/



	public Parser(Scanner scanner) {
		this.scanner = scanner;
		errors = new Errors();
	}

	void SynErr (int n) {
		if (errDist >= minErrDist) errors.SynErr(la.line, la.col, n);
		errDist = 0;
	}

	public void SemErr (string msg) {
		if (errDist >= minErrDist) errors.SemErr(t.line, t.col, msg);
		errDist = 0;
	}

  public void Warn (string msg) {
    Console.WriteLine("-- line " + t.line + " col " + t.col + ": " + msg);
  }

  public void Write (string filename) {
    List<string> output = new List<string>();
    foreach (Instruction i in header) {
      if (i.Item1 != "") {
        output.Add(i.Item1 + ": " + i.Item2);
      } else {
        output.Add(i.Item2);
      }
    }
    File.WriteAllLines(filename, output.ToArray());
  }

	void Get () {
		for (;;) {
			t = la;
			la = scanner.Scan();
			if (la.kind <= maxT) { ++errDist; break; }

			la = t;
		}
	}

	void Expect (int n) {
		if (la.kind==n) Get(); else { SynErr(n); }
	}

	bool StartOf (int s) {
		return set[s, la.kind];
	}

	void ExpectWeak (int n, int follow) {
		if (la.kind == n) Get();
		else {
			SynErr(n);
			while (!StartOf(follow)) Get();
		}
	}


	bool WeakSeparator(int n, int syFol, int repFol) {
		int kind = la.kind;
		if (kind == n) {Get(); return true;}
		else if (StartOf(repFol)) {return false;}
		else {
			SynErr(n);
			while (!(set[syFol, kind] || set[repFol, kind] || set[0, kind])) {
				Get();
				kind = la.kind;
			}
			return StartOf(syFol);
		}
	}


	void AddOp(out Instruction inst) {
		inst = new Instruction("", "Add"); 
		if (la.kind == 4) {
			Get();
		} else if (la.kind == 5) {
			Get();
			inst = new Instruction("", "Sub"); 
		} else SynErr(55);
	}

	void Expr(out TastierType type) {
		TastierType type1;
		Instruction inst;
		
		SimExpr(out type);
		if (StartOf(1)) {
			RelOp(out inst);
			SimExpr(out type1);
			if (type != type1)
			{
			 SemErr("incompatible types");
			}
			else
			{
			 program.Add(inst);
			 type = TastierType.Boolean;
			}
			
		}
	}

	void SimExpr(out TastierType type) {
		TastierType type1;
		Instruction inst;
		
		Term(out type);
		while (la.kind == 4 || la.kind == 5) {
			AddOp(out inst);
			Term(out type1);
			if (type != TastierType.Integer || type1 != TastierType.Integer)
			{
			SemErr("integer type expected");
			}
			program.Add(inst);
			
		}
	}

	void RelOp(out Instruction inst) {
		inst = new Instruction("", "Equ"); 
		switch (la.kind) {
		case 23: {
			Get();
			break;
		}
		case 24: {
			Get();
			inst = new Instruction("", "Lss"); 
			break;
		}
		case 25: {
			Get();
			inst = new Instruction("", "Lte"); 
			break;
		}
		case 26: {
			Get();
			inst = new Instruction("", "Gtr"); 
			break;
		}
		case 27: {
			Get();
			inst = new Instruction("", "Gte"); 
			break;
		}
		case 28: {
			Get();
			inst = new Instruction("", "Neq"); 
			break;
		}
		default: SynErr(56); break;
		}
	}

	void Factor(out TastierType type) {
		int n = 0;
		int m = 0;
		Symbol sym;
		string name,name1;
		name1 = "";
		bool isVar = true;
		
		type = TastierType.Undefined; 
		switch (la.kind) {
		case 1: {
			Ident(out name);
			if (la.kind == 6 || la.kind == 8 || la.kind == 12) {
				if (la.kind == 6) {
					Get();
					Expect(2);
					isVar = false;
					n = Convert.ToInt32(t.val);
					sym = lookup(openScopes, name);
					//factorFlag = 0;
					if (sym == null)
					{
					SemErr("reference to undefined variable " + name);
					}
					else
					{
					type = (TastierType)sym.Item3;
					if ( (TastierKind)sym.Item2 == TastierKind.Array)
					{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Load " +lexicalLevelDifference + " " + (sym.Item5+n+1)));
					} 
					else SemErr("variable expected");
					}
					
					if (la.kind == 6) {
						Get();
						Expect(2);
						isVar = false;
						m = Convert.ToInt32(t.val);
						Symbol newSym = lookup(openScopes,name);
						Symbol sym_Size = lookup(openScopes,name+"_size");
						
						// array bounds error
						if( (sym_Size.Item4 < m) || (0 > m) )
						{
						SemErr("Array index out of bounds!");
						}
						// store globally
						if (newSym.Item4 == 0)
						{
						program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
						}
						// store locally
						else
						{
						type = (TastierType)newSym.Item3;
						if(sym_Size == null)
						{
							SemErr("No array with the name: "+name);
						}
						int offset = (sym_Size.Item4 * n) + m ;
						int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
						program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (offset+1)));
						}
						
						Expect(7);
					} else if (la.kind == 7) {
						Get();
					} else SynErr(57);
				} else if (la.kind == 8) {
					Get();
					isVar = false;
					if (StartOf(2)) {
						if (StartOf(2)) {
							List<Symbol> template = new List<Symbol>();
							
							// Search the template list for the list of parameters
							// for the function in question
							foreach(List<Symbol> list in procParams)
							{
							if(list[0].Item1 == name)
							{								
							foreach(Symbol s in list)
								{
									template.Add(s);
								}
							}
							}
							int i = 1;
							int loc = paramLocation;
							
							while (StartOf(3)) {
								if (la.kind == 1) {
									Ident(out name1);
									if(loc <= 4070)
									{
									SemErr("Too many parameters on function call: " + name);
									}
									sym = lookup(openScopes,name1);
									if(sym == null)
									{
									SemErr("No such variable with the name: "+name1);
									}
									else
									{
									type = (TastierType)sym.Item3;
									if(template[i].Item3 != (int)type)
									{
										SemErr("Invalid type on variable: "+ name1);
									}
									int frame = Math.Abs(openScopes.Count - sym.Item4)-1;
									
									// Load then store the parameter
									program.Add(new Instruction("", "Load " +frame + " " + (sym.Item5)));
									program.Add(new Instruction("", "StoG " + loc) );
									loc = loc - 3;
									i++;
									}
									
								} else if (la.kind == 2) {
									Get();
									if(loc <= 4070)
									{
									SemErr("Too many parameters on function call: " + name);
									}
									if(template[i].Item3 != (int)TastierType.Integer)
									{
									SemErr("Expecting an int as a parameter");
									}
									n = Convert.ToInt32(t.val);
									// Store the values.
									program.Add(new Instruction("", "Const " + n));
									program.Add(new Instruction("", "StoG " + loc) );
									loc = loc - 3;
									i++;
									
								} else if (la.kind == 9) {
									Get();
									if(loc <= 4070)
									{
									SemErr("Too many parameters on function call: " + name);
									}
									if(template[i].Item3 != (int)TastierType.Boolean)
									{
									SemErr("Expecting an int as a parameter");
									}
									// store the values.
									program.Add(new Instruction("", "Const " + 1));
									program.Add(new Instruction("", "StoG " + loc) );
									loc = loc - 3;
									i++;
									
								} else {
									Get();
									if(loc <= 4070)
									{
									SemErr("Too many parameters on function call: " + name);
									}
									
									if(template[i].Item3 != (int)TastierType.Boolean)
									{
									SemErr("Expecting an int as a parameter");
									}
									// load and store the values.
									program.Add(new Instruction("", "Const " + 0));
									program.Add(new Instruction("", "StoG " + loc) );
									loc = loc - 3;
									i++;
									
								}
							}
						}
						sym = lookup(openScopes, name);
						if (sym == null)
						{
						SemErr("reference to undefined variable " + name);
						}
						if ((TastierKind)sym.Item2 != TastierKind.Proc)
						{
						SemErr("object is not a procedure");
						}
						
						type = (TastierType)sym.Item3;
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4);
						string procedureLabel = getLabelForProcedureName(lexicalLevelDifference, sym.Item1);
						
						if(type != TastierType.String)
						{
						// Call the function
						program.Add(new Instruction("", "Call " + lexicalLevelDifference + " " + procedureLabel));
						// Load the return value from memory.
						program.Add(new Instruction("", "LoadG " + returnLocation));
						}
						else
						{
						SemErr("Sorry procedures can't return strings");
						}
						
					}
					Expect(11);
				} else {
					Get();
					Ident(out name1);
					isVar = false;
					sym = lookup(openScopes, name+"_"+name1);
					// if there's an entry, check its a record
					if ((TastierKind)sym.Item2 == TastierKind.RecordVar)
					{
					type = (TastierType)sym.Item3;
					// then load the value associated with that record
					if (sym.Item4 == 0)
					{
						program.Add(new Instruction("", "LoadG " + (sym.Item5+3)));
					}
					else
					{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Load " + lexicalLevelDifference + " " + (sym.Item5+1)));
					}  
					} 
					else SemErr("record variable expected ERR: 2");
					
				}
			}
			if(isVar)
			{
			isVar = false;
			sym = lookup(openScopes, name);
			if (sym == null)
			{
				SemErr("reference to undefined variable " + name);
			}
			else
			{
				type = (TastierType)sym.Item3;
				
				if ( ((TastierKind)sym.Item2 == TastierKind.Var) 
									||((TastierKind)sym.Item2 == TastierKind.Constant) )
				{
					if (sym.Item4 == 0)
					{
						program.Add(new Instruction("", "LoadG " + (sym.Item5+3)));
					}
					else
					{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Load " +lexicalLevelDifference + " " + sym.Item5));
					}									
				} 
				else SemErr("variable expected ERR: 1");
			}
			}
			
			break;
		}
		case 2: {
			Get();
			n = Convert.ToInt32(t.val);
			program.Add(new Instruction("", "Const " + n));
			type = TastierType.Integer;
			
			break;
		}
		case 5: {
			Get();
			Factor(out type);
			if (type != TastierType.Integer)
			{
			SemErr("integer type expected");
			type = TastierType.Integer;
			}
			program.Add(new Instruction("", "Neg"));
			program.Add(new Instruction("", "Const 1"));
			program.Add(new Instruction("", "Add"));
			
			break;
		}
		case 9: {
			Get();
			program.Add(new Instruction("", "Const " + 1));
			type = TastierType.Boolean;
			
			break;
		}
		case 10: {
			Get();
			program.Add(new Instruction("", "Const " + 0));
			type = TastierType.Boolean;
			
			break;
		}
		case 3: {
			Get();
			type = TastierType.String;
			string theString = t.val;
			// save the address so it can be added to the symbol
			//lastAddress = stringIndex;
			// add each character to memory.
			stringSize = 0;
			// sift through the string only adding values that are 
			// not the '#' value or not an alphabetically letter or
			// special character
			foreach( char character in theString)
			{
			if(( (int)character != 39 ) && ((int)character > 31) )
			{
				stringSize++;
				program.Add(new Instruction("", "Const "+(int)character));
			}
			}
			// decrement the pointer in memory to the string.
			stringIndex = stringIndex - 3;
			
			break;
		}
		default: SynErr(58); break;
		}
	}

	void Ident(out string name) {
		Expect(1);
		name = t.val; 
	}

	void MulOp(out Instruction inst) {
		inst = new Instruction("", "Mul"); 
		if (la.kind == 13) {
			Get();
		} else if (la.kind == 14) {
			Get();
			inst = new Instruction("", "Div"); 
		} else SynErr(59);
	}

	void ProcDecl() {
		string name, name1;
		string label;
		Symbol sym = null;
		TastierType type;
		Scope currentScope = openScopes.Peek();
		int enterInstLocation = 0;
		int procType = 0;
		bool external = false;
		 
		if (la.kind == 15) {
			Get();
			procType = 0; 
		} else if (la.kind == 16) {
			Get();
			procType = 1; 
		} else if (la.kind == 17) {
			Get();
			procType = 2; 
		} else if (la.kind == 18) {
			Get();
			procType = 3; 
		} else SynErr(60);
		Ident(out name);
		currentScope.Push(new Symbol(name,
						(int)TastierKind.Proc, procType,
							openScopes.Count, -1));
		openScopes.Push(new Scope());
		currentScope = openScopes.Peek();
		
		List<Symbol> parameterList = new List<Symbol>();
		List<Instruction> toAdd = new List<Instruction>();
		parameterList.Add(new Symbol(name,0,0,0,0));
		// prints symbol
		check(name, 2);
		
		Expect(8);
		if (StartOf(4)) {
			int loc = paramLocation;
			int i = 0;
			int index = 1;// index starts at one, as index 0 is the name of the function
			
			while (la.kind == 46 || la.kind == 47 || la.kind == 48) {
				Type(out type);
				Ident(out name1);
				if(type == TastierType.String)
				{
				SemErr("Cannot pass Strings as parameters");
				}
				// accessing memory that isn't allowed.
				if(loc <= 4070)
				{
				SemErr("Too many parameters for a function, please use less");
				}
				
				// add the symbol to the current scope for the parameters.
				sym = new Symbol(name1,(int)TastierKind.Var, (int)type,
								openScopes.Count-1,
									currentScope.Count(s => s.Item2 == (int)TastierKind.Var));
				currentScope.Push(sym);
				
				// Load the parameter from memory
				toAdd.Add(new Instruction("","LoadG " + loc));
				// store at the current symbol's address.
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
				toAdd.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
				
				parameterList.Add(sym);
				
				loc = loc - 3;
				index++;
				
			}
			procParams.Add(parameterList);
			
			Expect(11);
		} else if (la.kind == 11) {
			Get();
		} else SynErr(61);
		Expect(19);
		program.Add(new Instruction("", "Enter 0"));
		
		enterInstLocation = program.Count - 1;
		label = generateProcedureName(name);
		openProcedureDeclarations.Push(name);
		/*
		This is where the compiler should add the instructions
		to initialise the constants declared outside of the
		runnable code
		*/
		if(name == "Main")
		{
		 // Iterate through the list
		 foreach (Symbol s in constantsList)
		 {
		program.Add(new Instruction("", "Const "+ s.Item4));
		program.Add(new Instruction("", "StoG " + ((s.Item5+3)-1)));
		 }
		
		}
		
		// Add the parameters to the function
		foreach(Instruction i in toAdd)
		{
		program.Add(i);
		}
		/*	Enter is supposed to have as an
		argument the next free address on the
		stack, but until we know how many
		local variables are in this procedure,
		we don't know what that is. We'll keep
		track of where we put the Enter
		instruction in the program so that
		later, when we know how many spaces on
		the stack have been allocated, we can
		put the right value in.
		*/
		
		while (StartOf(5)) {
			if (la.kind == 46 || la.kind == 47 || la.kind == 48) {
				VarDecl(external);
			} else if (StartOf(6)) {
				Stat();
			} else {
				openLabels.Push(generateLabel());
				program.Add(new Instruction("", "Jmp " + openLabels.Peek()));
				/*
				We need to jump over procedure
				definitions because otherwise we'll
				execute all the code inside them!
				Procedures should only be entered via
				a Call instruction.
				*/
				
				ProcDecl();
				program.Add(new Instruction(openLabels.Pop(), "Nop")); 
			}
		}
		if (la.kind == 20) {
			Get();
			Factor(out type);
			Expect(21);
			if(procType == 0)
			{
			 SemErr("Procedure of type: void, does not have return statement.");
			}
			else
			{
			// If the function returns an incompatible type, give an error
			if(((int) type != procType)&&(type != TastierType.Integer) )
			{
				SemErr("incompatible return type!");
			}
			
			// Store the Return Value in global Memory
			program.Add(new Instruction("", "StoG " + returnLocation));
			}
			
		}
		Expect(22);
		program.Add(new Instruction("", "Leave"));
		program.Add(new Instruction("", "Ret"));
		openScopes.Pop();
		// now we can generate the Enter instruction properly
		program[enterInstLocation] =
		new Instruction(label, "Enter " +
		currentScope.Count(s => s.Item2 == (int)TastierKind.Var));
		openProcedureDeclarations.Pop();
		
	}

	void Type(out TastierType type) {
		type = TastierType.Undefined; 
		if (la.kind == 46) {
			Get();
			type = TastierType.Integer; 
		} else if (la.kind == 47) {
			Get();
			type = TastierType.Boolean; 
		} else if (la.kind == 48) {
			Get();
			type = TastierType.String;  
		} else SynErr(62);
	}

	void VarDecl(bool external) {
		string name;
		TastierType type;
		Scope currentScope = openScopes.Peek();
		Symbol sym;
		int n;
		
		Type(out type);
		if (la.kind == 1) {
			Ident(out name);
			if (external)
			{
			 externalDeclarations.Push(new Symbol(name,
										(int)TastierKind.Var, (int)type, 0, 0));
			}
			else
			{
			//special case of strings.
			if(type != TastierType.String)
			{
				currentScope.Push(new Symbol(name,
								(int)TastierKind.Var, (int)type,
									openScopes.Count-1,
										currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
			}
			// push the size of the string and the string symbol in to the table.
			else
			{
				currentScope.Push(new Symbol(name,(int)TastierKind.Var, 
														(int)type,openScopes.Count-1,stringIndex));
				currentScope.Push(new Symbol(name+"_Size",(int)TastierKind.Var, 
												(int)type,openScopes.Count-1,
													currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
			}
			}
			// Print out the symbol
			check(name,1);
			
			while (la.kind == 51) {
				Get();
				Ident(out name);
				if (external)
				{
				 externalDeclarations.Push(new Symbol(name,
											(int)TastierKind.Var, (int)type, 0, 0));
				}
				else
				{
				//special case of strings.
				if(type != TastierType.String)
				{
					currentScope.Push(new Symbol(name,
									(int)TastierKind.Var, (int)type,
										openScopes.Count-1,
											currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
				}
				// push the size of the string and the string symbol in to the table.
				else
				{
					currentScope.Push(new Symbol(name,(int)TastierKind.Var, 
															(int)type,openScopes.Count-1,stringIndex));
					currentScope.Push(new Symbol(name+"_Size",(int)TastierKind.Var, 
													(int)type,openScopes.Count-1,
														currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
				}
				}
				// Print out the symbol
				check(name,1);
				
			}
		} else if (la.kind == 6) {
			Get();
			Expect(2);
			n = Convert.ToInt32(t.val); 
			Expect(7);
			if (la.kind == 1) {
				Ident(out name);
				sym = new Symbol(name,(int)TastierKind.Array, 
								(int)type, openScopes.Count-1,
										currentScope.Count(s => s.Item2 == (int)TastierKind.Array));
				currentScope.Push(sym);
				// add a new symbol for the array size
				sym = new Symbol(name+"_size",(int)TastierKind.Array_Size,(int)type,n,0);
				currentScope.Push(sym);
				for (int i = 0; i < n; i++)
				{
				//keep pushinng symbols associated with array[0], array[1] etc
				currentScope.Push(new Symbol(name+"Â£$%^"+i,
									(int)TastierKind.Var, (int)type,
										openScopes.Count-1,
											currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
				// Print out the symbol
				check(name+"Â£$%^",1);
				}
				
			} else if (la.kind == 6) {
				Get();
				Expect(2);
				int m = Convert.ToInt32(t.val);
				Expect(7);
				Ident(out name);
				sym = new Symbol(name,(int)TastierKind.Array, 
								(int)type, openScopes.Count-1,
									currentScope.Count(s => s.Item2 == (int)TastierKind.Array));
				currentScope.Push(sym);
				check(name,1);
				// push the size too
				sym = new Symbol(name+"_size",(int)TastierKind.Array_Size,(int)type,n,0);
				currentScope.Push(sym);
				check(name,1);
				for (int i = 0; i < n; i++)
				{
				for(int j = 0; j < m; j++)
				{
					//push the symbols associated with each element on to the stack
					
					currentScope.Push(new Symbol(name+"Â£$%^"+i+"_"+j,
										(int)TastierKind.Var, (int)type,
											openScopes.Count-1,
												currentScope.Count(s => s.Item2 == (int)TastierKind.Var)));
					sym = new Symbol(name+"_size"+i,(int)TastierKind.Array_Size,(int)type,m,0);
					currentScope.Push(sym);
				  // Print out the symbol
				  check(name+"Â£$%^_"+i+"_"+j,1);
				}
				}
				
			} else SynErr(63);
		} else SynErr(64);
		Expect(21);
	}

	void Stat() {
		TastierType type, type1, type2;
		string name, name1, name2;
		bool external = false;
		bool isExternal = false;
		Symbol sym;
		int n;
		
		switch (la.kind) {
		case 1: {
			Ident(out name);
			if (la.kind == 12) {
				Get();
				Ident(out name1);
				sym = lookup(openScopes,name);
				if(sym == null)
				{
				SemErr("There doesn't seem to a record with that name...");
				}
				else
				{
				// Look up the variable name
				sym = lookup(openScopes, name+"_"+name1);
				if(sym == null)
				{
					SemErr("Symbol name error: "+name+"_"+name1);
				}
				}
				
				Expect(29);
				Expr(out type);
				Expect(21);
				if (sym == null)
				{
				SemErr("reference to undefined variable " + name);
				}
				if(type != (TastierType)sym.Item3)
				{
				SemErr("incompatible type on symbol with name: "+ name);
				}
				procReturn = false;
				// Global declaration here.
				if (sym.Item4 == 0)
				{
				if (isExternal)
				{
					program.Add(new Instruction("", "StoG " + sym.Item1));
					// If the symbol is external, we also store it by name.
					// The linker will resolve the name to an address.
				}
				else
				{
					program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
				}
				}
				else
				{
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
				program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (sym.Item5+1)));
				}
				
			} else if (la.kind == 29) {
				Get();
				sym = lookup(openScopes, name);
				if (sym == null)
				{
				SemErr("reference to undefined variable " + name);
				}
				
				if (la.kind == 19) {
					Get();
					int i = 0;
					// check to make sure that the symbol is an array.
					if ( (TastierKind)sym.Item2 != TastierKind.Array )
					{
					SemErr("cannot assign to non-variable");
					}
					
					while (la.kind == 2 || la.kind == 9 || la.kind == 10) {
						if (la.kind == 2) {
							Get();
							n = Convert.ToInt32(t.val);
							Symbol newSym = lookup(openScopes,name);
							// if the types don't match
							if ((TastierType)newSym.Item3 != TastierType.Integer)
							{
							SemErr("incompatible types");
							}
							// recover the parameter from memory
							if (newSym.Item4 == 0)
							{
							program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
							}
							else
							{
							program.Add(new Instruction("", "Const " + n));
							int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
							program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (newSym.Item5+i+1)));
							i++;
							}	
							
						} else if (la.kind == 9) {
							Get();
							Symbol newSym = lookup(openScopes,name);
							// if the types don't match
							if ((TastierType)newSym.Item3 != TastierType.Boolean)
							{
							SemErr("incompatible types");
							}
							// get the parameter from memory
							if (newSym.Item4 == 0)
							{
							program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
							}
							// get the values from memory
							else
							{
							program.Add(new Instruction("", "Const " + 1));
							int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
							program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (newSym.Item5+i+1)));
							i++;
							}
							
						} else {
							Get();
							Symbol newSym = lookup(openScopes,name);
							// if the types don't match
							if ((TastierType)newSym.Item3 != TastierType.Boolean)
							{
							SemErr("incompatible types");
							}
							// then fetch the value from memory
							if (newSym.Item4 == 0)
							{
							program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
							}
							else
							{
							// store the boolean at the offset
							program.Add(new Instruction("", "Const " + 0));
							int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
							program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (newSym.Item5+i+1)));
							i++;
							}
							
						}
					}
					Expect(22);
					Expect(21);
				} else if (StartOf(7)) {
					Expr(out type);
					if (la.kind == 30) {
						Get();
						if(type != TastierType.Boolean)
						{
						SemErr("Boolean type expected for conditional assignment");
						}
						openLabels.Push(generateLabel());
						program.Add(new Instruction("", "FJmp " + openLabels.Peek()));
						
						Expr(out type1);
						if(type1 !=  (TastierType)sym.Item3)
						{
						SemErr("expression type before ':' not compatible with identifier");
						}
						if (sym.Item4 == 0)
						{
						program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
						}
						else
						{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Sto "+ lexicalLevelDifference + " " + sym.Item5));
						}
						Instruction startOfElse = new Instruction(openLabels.Pop(), "Nop");
						
						openLabels.Push(generateLabel());
						program.Add(new Instruction("", "Jmp " + openLabels.Peek()));
						program.Add(startOfElse);
						
						Expect(31);
						Expr(out type2);
						if(type2 !=  (TastierType)sym.Item3)
						{
						SemErr("expression type after ':' not compatible with identifier");
						}
						if (sym.Item4 == 0)
						{
						program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
						}
						else
						{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Sto "
						+ lexicalLevelDifference + " " + sym.Item5));
						}
						
						program.Add(new Instruction(openLabels.Pop(), "Nop"));
						
						Expect(21);
					} else if (la.kind == 21) {
						Get();
						if (sym == null)
						{
						SemErr("reference to undefined variable " + name);
						}
						if (type != (TastierType)sym.Item3) 
						{
						Console.WriteLine(type+" "+(TastierType)sym.Item3);
						SemErr("incompatible types on symbols with name: "+ name);
						}
						procReturn = false;
						// Global declaration here.
						if (sym.Item4 == 0)
						{
						if (isExternal)
						{
							program.Add(new Instruction("", "StoG " + sym.Item1));
							// If the symbol is external, we also store it by name.
							// The linker will resolve the name to an address.
						}
						else if(sym.Item2 == (int)TastierKind.Constant)
						{
							SemErr("Cannot re-assign constants!");
						}
						else
						{
							program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
						}
						}
						else
						{
						// if the symbol is a string
						if(sym.Item3 == (int)TastierType.String)
						{
							// get the size
							sym = lookup(openScopes,name+"_Size");
							program.Add(new Instruction("", "Const " + (stringSize)));
							
							int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
							program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
							// add that size to the record of the sizes
							stringSizes.Add(new Tuple<string,int>(name,stringSize));
							
							// repeatedly store the characters that are on the stack
							// decrementing the global string pointer
							for(int i = 0; i < stringSize; i++)
							{
								program.Add(new Instruction("", "StoG " + (stringIndex)));
								stringIndex = stringIndex - 3;
							}
							stringSize = 0;
						}
						else if(sym.Item2 == (int)TastierKind.Constant)
						{
							SemErr("Cannot re-assign constants!");
						}
						else
						{
							int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
							program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
						}
						
						}
						
					} else SynErr(65);
				} else SynErr(66);
			} else if (la.kind == 6) {
				Get();
				Expect(2);
				n = Convert.ToInt32(t.val); 
				Expect(7);
				if (la.kind == 29) {
					Get();
					Expr(out type1);
					Symbol newSym = lookup(openScopes,name);
					Symbol sym_Size = lookup(openScopes,name+"_size");
					
					// not the same type
					if ((TastierType)newSym.Item3 != type1)
					{
					SemErr("incompatible types");
					}
					// Array Access out of bounds
					if( (sym_Size.Item4 < n) || (0 > n) )
					{
					SemErr("Array index out of bounds!");
					}
					// store globally
					if (newSym.Item4 == 0)
					{
					program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
					}
					// store locally
					else
					{
					int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
					program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (newSym.Item5+n+1)));
					}
					
					Expect(21);
				} else if (la.kind == 6) {
					Get();
					Expect(2);
					int m = Convert.ToInt32(t.val);
					Expect(7);
					Expect(29);
					Expr(out type1);
					Symbol newSym = lookup(openScopes,name);
					Symbol sym_Size = lookup(openScopes,name+"_size");
					
					// if they're not the same type
					if ((TastierType)newSym.Item3 != type1)
					{
					SemErr("incompatible types");
					}
					// array bounds error
					if( (sym_Size.Item4 < m) || (0 > m) )
					{
					SemErr("Array index out of bounds!");
					}
					// store globally
					if (newSym.Item4 == 0)
					{
					program.Add(new Instruction("", "StoG " + (newSym.Item5+3)));
					}
					// store locally
					else
					{
					if(sym_Size == null)
					{
						SemErr("No array with the name: "+name);
					}
					int offset = sym_Size.Item4 + m;
					int lexicalLevelDifference = Math.Abs(openScopes.Count - newSym.Item4)-1;
					program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (offset+1)));
					}
					
					Expect(21);
				} else SynErr(67);
			} else if (la.kind == 8) {
				Get();
				if (StartOf(2)) {
					List<Symbol> template = new List<Symbol>();
					
					// Search the template list for the list of parameters
					// for the function in question
					foreach(List<Symbol> list in procParams)
					{
					if(list[0].Item1 == name)
					{								
						foreach(Symbol s in list)
						{
							template.Add(s);
						}
					}
					}
					// start at index 1 as to skip the procedure name
					// and the loc is where the 5 parameters should be stored
					int i = 1;
					int loc = paramLocation;
					
					while (StartOf(3)) {
						if (la.kind == 1) {
							Ident(out name1);
							if(loc <= 4070)
							{
							SemErr("Too many parameters");
							}
							sym = lookup(openScopes,name1);
							if(sym == null)
							{
							SemErr("No such variable with the name: "+name1);
							}
							else
							{
							TastierType tempType = (TastierType)sym.Item3;
							if(template[i].Item3 != (int)tempType)
							{
								SemErr("Invalid type on variable: "+ name1);
							}
							int frame = Math.Abs(openScopes.Count - sym.Item4)-1;
							
							// Load the identifier
							program.Add(new Instruction("", "Load " +frame + " " + (sym.Item5)));
							 
							// then store it.
							program.Add(new Instruction("", "StoG " + loc) );
							// move to the next place in memory and the next type in
							// in the template.
							loc = loc - 3;
							i++;
							}
							
						} else if (la.kind == 2) {
							Get();
							if(loc <= 4070)
							{
							SemErr("Too many parameters");
							}
							if(template[i].Item3 != (int)TastierType.Integer)
							{
							//Console.WriteLine(template[i].Item3);
							SemErr("Expecting an int as a parameter");
							}
							n = Convert.ToInt32(t.val);
							program.Add(new Instruction("", "Const " + n));
							program.Add(new Instruction("", "StoG " + loc) );
							loc = loc - 3;
							i++;
							
						} else if (la.kind == 9) {
							Get();
							if(loc <= 4070)
							{
							SemErr("Too many parameters");
							}
							if(template[i].Item3 != (int)TastierType.Boolean)
							{
							SemErr("Expecting an bool as a parameter");
							}
							// store true in the memory location
							program.Add(new Instruction("", "Const " + 1));
							program.Add(new Instruction("", "StoG " + loc) );
							loc = loc - 3;
							i++;
							
						} else {
							Get();
							if(loc <= 4070)
							{
							SemErr("Too many parameters");
							}
							if(template[i].Item3 != (int)TastierType.Boolean)
							{
							SemErr("Expecting an bool as a parameter");
							}
							// store false in the memory location
							program.Add(new Instruction("", "Const " + 0));
							program.Add(new Instruction("", "LoadG " + loc) );
							loc = loc - 3;
							i++;
							
						}
					}
					Expect(11);
				} else if (la.kind == 11) {
					Get();
				} else SynErr(68);
				Expect(21);
				sym = lookup(openScopes, name);
				if (sym == null)
				{
				SemErr("reference to undefined variable " + name);
				}
				if ((TastierKind)sym.Item2 != TastierKind.Proc)
				{
				SemErr("object is not a procedure");
				}
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4);
				string procedureLabel = getLabelForProcedureName(lexicalLevelDifference, sym.Item1);
				program.Add(new Instruction("", "Call " + lexicalLevelDifference + " " + procedureLabel));
				
			} else SynErr(69);
			break;
		}
		case 32: {
			Get();
			Expect(8);
			Expr(out type);
			Expect(11);
			if ((TastierType)type != TastierType.Boolean)
			{
			SemErr("boolean type expected");
			}
			openLabels.Push(generateLabel());
			program.Add(new Instruction("", "FJmp " + openLabels.Peek()));
			
			Stat();
			Instruction startOfElse = new Instruction(openLabels.Pop(), "Nop");
			/*
			If we got into the "if", we need to
			jump over the "else" so that it
			doesn't get executed.
			*/
			openLabels.Push(generateLabel());
			program.Add(new Instruction("", "Jmp " + openLabels.Peek()));
			program.Add(startOfElse);
			
			if (la.kind == 33) {
				Get();
				Stat();
			}
			program.Add(new Instruction(openLabels.Pop(), "Nop")); 
			break;
		}
		case 34: {
			Get();
			string loopStartLabel = generateLabel();
			openLabels.Push(generateLabel()); //second label is for the loop end
			program.Add(new Instruction(loopStartLabel, "Nop"));
			
			Expect(8);
			Expr(out type);
			Expect(11);
			if ((TastierType)type != TastierType.Boolean) 
			{
			SemErr("boolean type expected");
			}
			program.Add(new Instruction("", "FJmp " + openLabels.Peek())); // jump to the loop end label if condition is false
			
			Stat();
			program.Add(new Instruction("", "Jmp " + loopStartLabel));
			program.Add(new Instruction(openLabels.Pop(), "Nop")); // put the loop end label here
			
			break;
		}
		case 35: {
			Get();
			string loopStartLabel = generateLabel();
			string loopEndLabel = generateLabel();
			
			Expect(8);
			Ident(out name);
			Expect(29);
			Expr(out type);
			sym = lookup(openScopes, name);
			if (sym == null)
			{
			SemErr("undefined variable " + name);
			}
			if((TastierType)sym.Item3 != type)
			{
			SemErr("incompatible types in the for loop declaration");
			}
			if (sym.Item4 == 0)
			{
			program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
			}
			else
			{
			int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
			program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
			}
			program.Add(new Instruction(loopStartLabel, "Nop"));
			
			Expect(21);
			Expr(out type2);
			if(type2 != TastierType.Boolean)
			{
			SemErr("Boolean condition needed here");
			}
			// jump to the loop end label if condition is false
			program.Add(new Instruction("", "FJmp " + loopEndLabel)); 
			
			Expect(21);
			Ident(out name);
			Expect(29);
			Expr(out type2);
			if (type2 != (TastierType)sym.Item3)
			{
			SemErr("incompatible types");
			}
			//afterCondtion
			
			Expect(11);
			if (la.kind == 19) {
				Get();
				if (la.kind == 22) {
					if (sym.Item4 == 0)
					{
					program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
					}
					else
					{
					int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
					program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
					}
					program.Add(new Instruction("", "Jmp " + loopStartLabel));
					program.Add(new Instruction(loopEndLabel, "Nop")); // put the loop end label here
					
					Get();
				} else if (StartOf(8)) {
					while (StartOf(9)) {
						if (StartOf(6)) {
							Stat();
						} else {
							VarDecl(external);
						}
					}
					if (sym.Item4 == 0)
					{
					program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
					}
					else
					{
					int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
					program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
					}
					program.Add(new Instruction("", "Jmp " + loopStartLabel));
					
					Expect(22);
					program.Add(new Instruction(loopEndLabel, "Nop"));
				} else SynErr(70);
			} else if (StartOf(6)) {
				Stat();
				if (sym.Item4 == 0)
				{
				program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
				}
				else
				{
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
				program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
				}
				program.Add(new Instruction("", "Jmp " + loopStartLabel));
				program.Add(new Instruction(loopEndLabel, "Nop")); // put the loop end label here
				
			} else if (la.kind == 21) {
				Get();
				if (sym.Item4 == 0)
				{
				program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
				}
				else
				{
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
				program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
				}
				program.Add(new Instruction("", "Jmp " + loopStartLabel));
				program.Add(new Instruction(loopEndLabel, "Nop")); // put the loop end label here
				
			} else SynErr(71);
			break;
		}
		case 36: {
			Get();
			Ident(out name);
			Expect(21);
			sym = lookup(openScopes, name);
			if (sym == null)
			{
			sym = _lookup(externalDeclarations, name);
			isExternal = true;
			}
			if (sym == null)
			{
			SemErr("reference to undefined variable " + name);
			}
			
			if (sym.Item2 != (int)TastierKind.Var)
			{
			SemErr("variable type expected but " + sym.Item1
			+ " has kind " + (TastierType)sym.Item2);
			}
			
			if (sym.Item3 != (int)TastierType.Integer)
			{
			SemErr("integer type expected but " + sym.Item1
					+ " has type " + (TastierType)sym.Item2);
			}
			program.Add(new Instruction("", "Read"));
			
			if (sym.Item4 == 0)
			{
			if (isExternal)
			{
			program.Add(new Instruction("", "StoG " + sym.Item1));
			// if the symbol is external, we also
			// store it by name. The linker will
			// resolve the name to an address.
			}
			else
			{
			program.Add(new Instruction("", "StoG " + (sym.Item5+3)));
			}
			}
			else
			{
			int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
			program.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + sym.Item5));
			}
			
			break;
		}
		case 37: {
			Get();
			Ident(out name);
			Expect(6);
			int val = 0;
			n = 0;
			
			Expect(2);
			val = Convert.ToInt32(t.val); 
			Expect(7);
			if (la.kind == 6) {
				int m = 0;
				Get();
				Expect(2);
				m = Convert.ToInt32(t.val); 
				Expect(7);
				sym = lookup(openScopes, name);
				// no such array with that name
				if (sym == null)
				{
				SemErr("reference to undefined variable " + name);
				}
				else
				{
				// otherwise, make sure the variable is an array
				if ((TastierKind)sym.Item2 == TastierKind.Array) 
				{
					if (sym.Item4 == 0)
					{
						program.Add(new Instruction("", "LoadG " + (sym.Item5+3)));
					}
					else
					{
						// then load the value from the offset at the base address
						Symbol size = lookup(openScopes,name+"_size");
						Symbol size1 = lookup(openScopes,name+"_size"+n);
						if(size == null)
						{
							SemErr("No array with the name: "+name);
						}
						Console.WriteLine(size.Item1 +" "+size.Item4+ " "+size1.Item4);
						int offset = (size.Item4 * size1.Item4) + m +1;
						
						
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Load " + lexicalLevelDifference + " " + (offset+1)));
					}
				} 
				else SemErr("variable expected");
				}
				
				Expect(21);
				program.Add(new Instruction("", "Write")); 
			} else if (la.kind == 21) {
				Get();
				sym = lookup(openScopes, name);
				// no such array with that name
				if (sym == null)
				{
				SemErr("reference to undefined variable " + name);
				}
				// otherwise, load the value if there is an identifier with that name
				// and is a array, using the offset value of 'val' + 1 (plus 1 due to there
				// being an extra symbol to store the array size.)
				else
				{
				type = (TastierType)sym.Item3;
				if ((TastierKind)sym.Item2 == TastierKind.Array) 
				{
					if (sym.Item4 == 0)
					{
						program.Add(new Instruction("", "LoadG " + (sym.Item5+3)));
					}
					else
					{
						int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
						program.Add(new Instruction("", "Load " + lexicalLevelDifference + " " + (sym.Item5+val+1)));
					}
				} else SemErr("variable expected");
				}
				
				program.Add(new Instruction("", "Write")); 
			} else SynErr(72);
			break;
		}
		case 38: {
			Get();
			Expr(out type);
			Expect(21);
			program.Add(new Instruction("", "Write"));
			
			break;
		}
		case 39: {
			Get();
			Ident(out name);
			Expect(12);
			Ident(out name1);
			sym = lookup(openScopes, name+"_"+name1);
			// if there's an entry, check its a record
			if ((TastierKind)sym.Item2 == TastierKind.RecordVar)
			{
			
			int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
			program.Add(new Instruction("", "Load " + lexicalLevelDifference + " " + (sym.Item5+1)));
			  
			} 
			else SemErr("record variable expected");
			program.Add(new Instruction("", "Write"));
			
			Expect(21);
			break;
		}
		case 40: {
			Get();
			while (la.kind == 1 || la.kind == 3) {
				if (la.kind == 1) {
					Ident(out name);
					Symbol sym_Size = lookup(openScopes,name+"_Size");
					sym = lookup(openScopes,name);
					if(sym_Size == null)
					{
					SemErr("No such string called: "+name);
					}
					// otherwise, find the strings length in the list tuple and load 
					// the string out of memory.
					else
					{
					int size = 0;
					int address = sym.Item5-3;
					foreach( Tuple<string,int> strS in stringSizes)
					{
						if(name == strS.Item1)
						{
							size = strS.Item2;
						}
					}
					// add that many values on to the stack
					for(int i = 0 ; i < size; i++)
					{
						program.Add(new Instruction("", "LoadG " + (address)));
						address = address - 3;
					}
					// pushes the size of the string on to the stack, so the write function knows
					// how many to pop off.
					int lexicalLevelDifference = Math.Abs(openScopes.Count - sym_Size.Item4)-1;
					program.Add(new Instruction("", "Load " + lexicalLevelDifference + " " + (sym_Size.Item5)));
					// call writeStr.
					program.Add(new Instruction("", "WriteStr")); 
					stringSize = 0;
					}
					
				} else {
					Get();
					type = TastierType.String;
					string theString = t.val;
					// save the address so it can be added to the symbol
					//lastAddress = stringIndex;
					// add each character to memory.
					int size = 0;
					List<Instruction> rawString = new List<Instruction>();
					// get the size of the current list and add an instruction for the
					// value
					foreach( char character in theString)
					{
					if( ((int)character != 39 )&& ((int)character > 31) )
					{
						size++;
						rawString.Add(new Instruction("", "Const "+(int)character));
					}
					}
					
					// values are placed in reverse order, need to place
					/// them in the correct order again.
					for(int i = rawString.Count-1; i != -1; i--)
					{
					program.Add(rawString[i]);
					}
					// Add the size of the string and call writeStr.
					program.Add(new Instruction("", "Const "+size));
					program.Add(new Instruction("", "WriteStr")); 
					
				}
			}
			Expect(21);
			break;
		}
		case 41: {
			Get();
			Expect(8);
			Factor(out type);
			Expect(11);
			Instruction lastInst = program[program.Count-1];
			// a list of strings that contain each label for
			// for the cases should they not evaluate to be
			// true.
			List<String> listOfLabels = new List<String>();
			string defaultLabel = generateLabel();
			//Console.WriteLine(type);
			if(type == TastierType.Boolean)
			{
			SemErr("Cannot have a boolean in a switch!");
			}
			else if(type == TastierType.String)
			{
			SemErr("Cannot have a string in a switch!");
			}
			// I remove the instruction that the Expr uses as if I leave 
			// it on list of instruction to execute, there might be a 
			// value that is loaded in wrong somewhere with the Expr's value
			program.RemoveAt((program.Count)-1);
			
			Expect(19);
			if (la.kind == 22) {
				Get();
			} else if (la.kind == 42 || la.kind == 43) {
				while (la.kind == 42) {
					program.Add(lastInst);
					
					Get();
					Expr(out type1);
					program.Add(new Instruction("", "Equ"));
					listOfLabels.Add(generateLabel());
					// jumps to the next case if it is false, otherwise
					// continues as normal.
					program.Add(new Instruction("", "FJmp " + listOfLabels[listOfLabels.Count - 1]));
					
					if(type != type1)
					{
					SemErr("case statement type is not the same as switch type!.");
					}
					
					Expect(31);
					while (StartOf(9)) {
						if (StartOf(6)) {
							Stat();
						} else {
							VarDecl(external);
						}
					}
					program.Add(new Instruction("", "Jmp " + defaultLabel));
					// label for the next case, should the evaluation be false.
					program.Add(new Instruction(listOfLabels[listOfLabels.Count - 1], "Nop"));
					
				}
				Expect(43);
				Expect(31);
				while (StartOf(9)) {
					if (StartOf(6)) {
						Stat();
					} else {
						VarDecl(external);
					}
				}
				program.Add(new Instruction(defaultLabel, "Nop")); 
				Expect(22);
			} else SynErr(73);
			break;
		}
		case 44: {
			Get();
			Ident(out name2);
			Ident(out name);
			List <Symbol>  newRecord = new List <Symbol>(); 
			List <Symbol>  recordToCompare = new List <Symbol>(); 
			bool allowCreate = false;
			
			sym = lookup(openScopes,name);
			// if there's no symbol, make an entry for this record.
			if(sym == null)
			{
			// search the record template list for an entry with 
			// the same name as name2
			foreach ( List <Symbol> l in recordListTemplate)
			{
				foreach ( Symbol s in l)
				{
					if(s.Item1 == name2)
					{
						recordToCompare = l;
						allowCreate = true;
					}
				}
			}
			if(allowCreate)
			{
				// Add the Ident of the Record to the list and the stack
				sym = new Symbol (name,(int) TastierKind.RecordInst,
										(int) TastierType.Undefined,
										openScopes.Peek().Count-1,
											openScopes.Peek().Count(s => s.Item2 == (int) TastierKind.RecordInst));
				newRecord.Add(sym);
				//Add the record to the symbol Table.
				openScopes.Peek().Push(sym);
			}
			else
			{
				SemErr("No record declaration with this name: "+ name2);
			}
			}
			else
			{
			SemErr("Already a record with this name: '"+name+"'");
			}
			
			Expect(8);
			List <Instruction> toAdd = new List<Instruction>();
			while (la.kind == 46 || la.kind == 47 || la.kind == 48) {
				Type(out type1);
				Ident(out name1);
				sym = lookup(openScopes,name1);
				if(sym == null)
				{
				int v = openScopes.Peek().Count-1;
				int p = openScopes.Peek().Count(s => s.Item2 == (int) TastierKind.RecordVar);
				sym = new Symbol (name+"_"+name1, (int)TastierKind.RecordVar,(int)type1, v, p );
				newRecord.Add(sym);
				}
				else
				{
				SemErr("Already a record variable with that name: '"+name1+"'");
				}
				
				Expect(29);
				Expr(out type);
				int lexicalLevelDifference = Math.Abs(openScopes.Count - sym.Item4)-1;
				toAdd.Add(new Instruction("", "Sto " + lexicalLevelDifference + " " + (sym.Item5+1)));
				
				Expect(21);
			}
			Expect(11);
			if(newRecord.Count != recordToCompare.Count)
			{
			SemErr("Not the same number of record variables as the template!");
			}
			else
			{
			// start at index 1 because index 0 will be the names of both 
			// the template name the record name
			for(int i = 1; i < newRecord.Count; i++)
			{
				if((newRecord[i].Item3 != recordToCompare[i].Item3) &&
							(newRecord[i].Item1 != recordToCompare[i].Item1))
				{
						SemErr("Not the same symbol for the given record: "+newRecord[i].Item1);
					}
				}
				recordInstances.Add(newRecord);
				// Adds each symbol to the symbol table.
				// Add the instruction to store then too.
				foreach(Symbol s in newRecord)
				{
					printSymbol(s);
					openScopes.Peek().Push(s);
				}
				// Add the instructions to the program.
				foreach(Instruction ins in toAdd)
				{
					program.Add(ins);
				}
			}
			
			
			Expect(21);
			break;
		}
		case 19: {
			Get();
			while (StartOf(9)) {
				if (StartOf(6)) {
					Stat();
				} else {
					VarDecl(external);
				}
			}
			Expect(22);
			break;
		}
		default: SynErr(74); break;
		}
	}

	void Term(out TastierType type) {
		TastierType type1;
		Instruction inst;
		
		Factor(out type);
		while (la.kind == 13 || la.kind == 14) {
			MulOp(out inst);
			Factor(out type1);
			if (type != TastierType.Integer || type1 != TastierType.Integer)
			{
			SemErr("integer type expected");
			}
			program.Add(inst);
			    
		}
	}

	void Tastier() {
		string name; bool external = false; 
		Expect(45);
		Ident(out name);
		openScopes.Push(new Scope()); 
		Expect(19);
		while (la.kind == 49) {
			structDecl();
		}
		while (la.kind == 50) {
			ConstDecl();
		}
		while (StartOf(10)) {
			if (la.kind == 46 || la.kind == 47 || la.kind == 48) {
				VarDecl(external);
			} else if (StartOf(11)) {
				ProcDecl();
			} else {
				ExternDecl();
			}
		}
		Expect(22);
		if (openScopes.Peek().Count == 0)
		{
		 Warn("Warning: Program " + name + " is empty ");
		}
		
		header.Add(new Instruction("", ".names "
								+ (externalDeclarations.Count
									+ openScopes.Peek().Count)));
		foreach (Symbol s in openScopes.Peek())
		{
		 // Adds the 'const' to the language
		 if ((s.Item2 == (int)TastierKind.Var)||(s.Item2 == (int)TastierKind.Constant))
		 {
		header.Add(new Instruction("", ".var "+ ((int)s.Item3) + " " + s.Item1));
		 }
		 else if (s.Item2 == (int)TastierKind.Proc)
		 {
		header.Add(new Instruction("", ".proc " + s.Item1));
		 }
		 else if ( (s.Item2 == (int)TastierKind.RecordDecl) )
		 {
		header.Add(new Instruction("", ".recordDecl " + s.Item1));
		 }
		 else if ((s.Item2 == (int)TastierKind.RecordVar))
		 {
		header.Add(new Instruction("", ".var "+ ((int)s.Item3) + " " + s.Item1));
		 }
		 else
		 {
		SemErr("global item " + s.Item1 + " has no defined type");
		 }
		}
		foreach (Symbol s in externalDeclarations)
		{
		 if (s.Item2 == (int)TastierKind.Var)
		 {
		header.Add(new Instruction("", ".external var "+ ((int)s.Item3) + " "
		+ s.Item1));
		 }
		 else if (s.Item2 == (int)TastierKind.Proc)
		 {
		header.Add(new Instruction("", ".external proc "+ s.Item1));
		 }
		 else
		 {
		SemErr("external item "	+ s.Item1 + " has no defined type");
		 }
		}
		header.AddRange(program);
		openScopes.Pop();
		    
	}

	void structDecl() {
		string name,name1;
		Symbol sym;
		TastierType type;
		Scope currentScope = openScopes.Peek();
		List <Symbol> tempListOfSymbols = new List<Symbol>();
		
		Expect(49);
		Ident(out name);
		sym = lookup(openScopes,name);
		if(sym == null)
		{
		sym = new Symbol(name,(int)TastierKind.RecordDecl,
							(int)TastierType.Undefined,
								openScopes.Count-1,
									currentScope.Count(s => s.Item2 == (int) TastierKind.RecordDecl));
		printSymbol(sym);
		tempListOfSymbols.Add(sym);
		currentScope.Push(sym);
		}
		else
		{
		SemErr("Already a symbol with that name! Please use another!");
		}
		
		Expect(19);
		while (la.kind == 46 || la.kind == 47 || la.kind == 48) {
			Type(out type);
			Ident(out name1);
			tempListOfSymbols.Add(new Symbol(name1,(int)TastierKind.Var,
									(int)type,openScopes.Count-1,
										currentScope.Count(s => s.Item2 == (int) TastierKind.Var)));	
			
			Expect(21);
		}
		recordListTemplate.Add(tempListOfSymbols); 
		Expect(22);
		Expect(21);
	}

	void ConstDecl() {
		string name;
		int n;
		Symbol sym;
		TastierType type;
		Scope currentScope = openScopes.Peek();
		
		Expect(50);
		Type(out type);
		Ident(out name);
		sym = lookup(openScopes,name);
		if(sym == null)
		{
		  sym = new Symbol(name,(int)TastierKind.Constant,
							(int)type,
								openScopes.Count-1,
									currentScope.Count(s => s.Item2 == (int)TastierKind.Constant));
		  currentScope.Push(sym);
		}
		// otherwise it was already declared.
		else
		{
		  SemErr(name+"is already declared!");
		}
		encounteredConstant = true;
		    
		Expect(29);
		while (la.kind == 2 || la.kind == 9 || la.kind == 10) {
			if (la.kind == 2) {
				Get();
				n = Convert.ToInt32(t.val);
				type = TastierType.Integer;
				constantsList.Add(new Symbol(name,
											(int)TastierKind.Constant,(int)type,n,
												currentScope.Count(s => s.Item2 == (int)TastierKind.Constant)));
				       
			} else if (la.kind == 9) {
				Get();
				type = TastierType.Boolean;
				constantsList.Add(new Symbol(name,
											(int)TastierKind.Constant,(int)type,1,
												currentScope.Count(s => s.Item2 == (int)TastierKind.Constant)));
				       
			} else {
				Get();
				type = TastierType.Boolean;
				constantsList.Add(new Symbol(name,
											(int)TastierKind.Constant,(int)type,0,
												currentScope.Count(s => s.Item2 == (int)TastierKind.Constant)));
				        
			}
		}
		Expect(21);
	}

	void ExternDecl() {
		string name;
		bool external = true;
		
		Expect(52);
		if (la.kind == 46 || la.kind == 47 || la.kind == 48) {
			VarDecl(external);
		} else if (la.kind == 53) {
			Get();
			Ident(out name);
			Expect(21);
			externalDeclarations.Push(new Symbol(name,
			(int)TastierKind.Proc, (int)TastierType.Undefined, 1, -1)); 
		} else SynErr(75);
	}



	public void Parse() {
		la = new Token();
		la.val = "";
		Get();
		Tastier();
		Expect(0);

	}

	static readonly bool[,] set = {
		{T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x},
		{x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, T,T,T,T, T,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x},
		{x,T,T,x, x,x,x,x, x,T,T,T, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x},
		{x,T,T,x, x,x,x,x, x,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x},
		{x,x,x,x, x,x,x,x, x,x,x,T, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,T,T, T,x,x,x, x,x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,x,x,T, T,T,T,T, x,x,x,x, x,x,x,x, x,x,x,x, T,x,T,T, T,T,T,T, T,T,x,x, T,x,T,T, T,x,x,x, x,x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, x,x,x,x, x,x,x,x, x,x,x,x, T,x,T,T, T,T,T,T, T,T,x,x, T,x,x,x, x,x,x,x, x,x,x,x},
		{x,T,T,T, x,T,x,x, x,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, x,x,T,x, x,x,x,x, x,x,x,x, T,x,T,T, T,T,T,T, T,T,x,x, T,x,T,T, T,x,x,x, x,x,x,x},
		{x,T,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, x,x,x,x, x,x,x,x, x,x,x,x, T,x,T,T, T,T,T,T, T,T,x,x, T,x,T,T, T,x,x,x, x,x,x,x},
		{x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, T,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,T,T, T,x,x,x, T,x,x,x},
		{x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,T, T,T,T,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x, x,x,x,x}

	};
} // end Parser


public class Errors {
	public int count = 0;                                    // number of errors detected
	public System.IO.TextWriter errorStream = Console.Out;   // error messages go to this stream
	public string errMsgFormat = "-- line {0} col {1}: {2}"; // 0=line, 1=column, 2=text

	public virtual void SynErr (int line, int col, int n) {
		string s;
		switch (n) {
			case 0: s = "EOF expected"; break;
			case 1: s = "ident expected"; break;
			case 2: s = "number expected"; break;
			case 3: s = "stringValues expected"; break;
			case 4: s = "\"+\" expected"; break;
			case 5: s = "\"-\" expected"; break;
			case 6: s = "\"[\" expected"; break;
			case 7: s = "\"]\" expected"; break;
			case 8: s = "\"(\" expected"; break;
			case 9: s = "\"true\" expected"; break;
			case 10: s = "\"false\" expected"; break;
			case 11: s = "\")\" expected"; break;
			case 12: s = "\":>\" expected"; break;
			case 13: s = "\"*\" expected"; break;
			case 14: s = "\"/\" expected"; break;
			case 15: s = "\"void\" expected"; break;
			case 16: s = "\"int:\" expected"; break;
			case 17: s = "\"bool:\" expected"; break;
			case 18: s = "\"string:\" expected"; break;
			case 19: s = "\"{\" expected"; break;
			case 20: s = "\"return\" expected"; break;
			case 21: s = "\";\" expected"; break;
			case 22: s = "\"}\" expected"; break;
			case 23: s = "\"=\" expected"; break;
			case 24: s = "\"<\" expected"; break;
			case 25: s = "\"<=\" expected"; break;
			case 26: s = "\">\" expected"; break;
			case 27: s = "\">=\" expected"; break;
			case 28: s = "\"!=\" expected"; break;
			case 29: s = "\":=\" expected"; break;
			case 30: s = "\"?\" expected"; break;
			case 31: s = "\":\" expected"; break;
			case 32: s = "\"if\" expected"; break;
			case 33: s = "\"else\" expected"; break;
			case 34: s = "\"while\" expected"; break;
			case 35: s = "\"for\" expected"; break;
			case 36: s = "\"read\" expected"; break;
			case 37: s = "\"writeArray\" expected"; break;
			case 38: s = "\"write\" expected"; break;
			case 39: s = "\"writeRecordVal\" expected"; break;
			case 40: s = "\"writeString\" expected"; break;
			case 41: s = "\"switch\" expected"; break;
			case 42: s = "\"case\" expected"; break;
			case 43: s = "\"default\" expected"; break;
			case 44: s = "\"create\" expected"; break;
			case 45: s = "\"program\" expected"; break;
			case 46: s = "\"int\" expected"; break;
			case 47: s = "\"bool\" expected"; break;
			case 48: s = "\"string\" expected"; break;
			case 49: s = "\"init\" expected"; break;
			case 50: s = "\"constant\" expected"; break;
			case 51: s = "\",\" expected"; break;
			case 52: s = "\"external\" expected"; break;
			case 53: s = "\"procedure\" expected"; break;
			case 54: s = "??? expected"; break;
			case 55: s = "invalid AddOp"; break;
			case 56: s = "invalid RelOp"; break;
			case 57: s = "invalid Factor"; break;
			case 58: s = "invalid Factor"; break;
			case 59: s = "invalid MulOp"; break;
			case 60: s = "invalid ProcDecl"; break;
			case 61: s = "invalid ProcDecl"; break;
			case 62: s = "invalid Type"; break;
			case 63: s = "invalid VarDecl"; break;
			case 64: s = "invalid VarDecl"; break;
			case 65: s = "invalid Stat"; break;
			case 66: s = "invalid Stat"; break;
			case 67: s = "invalid Stat"; break;
			case 68: s = "invalid Stat"; break;
			case 69: s = "invalid Stat"; break;
			case 70: s = "invalid Stat"; break;
			case 71: s = "invalid Stat"; break;
			case 72: s = "invalid Stat"; break;
			case 73: s = "invalid Stat"; break;
			case 74: s = "invalid Stat"; break;
			case 75: s = "invalid ExternDecl"; break;

			default: s = "error " + n; break;
		}
		errorStream.WriteLine(errMsgFormat, line, col, s);
		count++;
	}

	public virtual void SemErr (int line, int col, string s) {
		errorStream.WriteLine(errMsgFormat, line, col, s);
		count++;
	}

	public virtual void SemErr (string s) {
		errorStream.WriteLine(s);
		count++;
	}

	public virtual void Warning (int line, int col, string s) {
		errorStream.WriteLine(errMsgFormat, line, col, s);
	}

	public virtual void Warning(string s) {
		errorStream.WriteLine(s);
	}
} // Errors


public class FatalError: Exception {
	public FatalError(string m): base(m) {}
}
}