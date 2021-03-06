grammar Compiler;

options {
    language=Python3;
}

@parser::header {
from compiler.objects import *
from compiler.antlr import CompilerLexer
import itertools
import antlr4
from antlr4.error.ErrorListener import ErrorListener

class MyErrorListener(ErrorListener):
    def __init__(self, context):
        super(MyErrorListener, self).__init__()
        self._context = context

    def syntaxError(self, recognizer, offendingSymbol, line, column, msg, e):
        raise ParseError(self._context, line, column, msg)

    def reportAmbiguity(self, recognizer, dfa, startIndex, stopIndex, exact, ambigAlts, configs):
        pass

    def reportAttemptingFullContext(self, recognizer, dfa, startIndex, stopIndex, conflictingAlts, configs):
        pass

    def reportContextSensitivity(self, recognizer, dfa, startIndex, stopIndex, prediction, configs):
        pass
}

@parser::members {
def setContext(self, context):
    self.context = context

@staticmethod
def parse(source, context):
    lexer = CompilerLexer.CompilerLexer(antlr4.InputStream(source))
    lexer._listeners = [MyErrorListener(context)]
    stream = antlr4.CommonTokenStream(lexer)
    parser = CompilerParser(stream)
    parser._listeners = [MyErrorListener(context)]
    parser.setContext(context)

    root = parser.root().v
    root.typecheck()
    root.optimize()

    return root.seq
}

expr returns [v]
    : BOOL                                 {$v = BoolStatement(self.context, $BOOL.text == 'true', ($BOOL.line, $BOOL.pos))}
    | INT                                  {$v = ConstIntStatement(self.context, $INT.int, ($INT.line, $INT.pos))}
    | def_lambda                           {$v = $def_lambda.v}
    | '(' e=expr ')'                       {$v = $e.v}
    | ID                                   {$v = GetVariableStatement(self.context, $ID.text, ($ID.line, $ID.pos))}
    | <assoc=right> e=expr call_arguments  {$v = FunctionExprCallStatement(self.context, $e.v, $call_arguments.v, $e.v._position).call_from_expression()}
    // operators:
    |         o='-'                e =expr {$v = UnaryOperatorStatement(self.context, $o.text, $e.v, ($o.line, $o.pos))}
    | e1=expr o=('*'  | '/' | '%') e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    | e1=expr o=('+'  | '-')       e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    | e1=expr o=('<'  | '<='
                |'>'  | '>=')      e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    | e1=expr o=('==' | '!=')      e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    |         o=('!'  | 'not')     e =expr {$v = UnaryOperatorStatement(self.context, $o.text, $e.v, ($o.line, $o.pos))}
    | e1=expr o=('&&' | 'and')     e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    | e1=expr o=('||' | 'or')      e2=expr {$v = OperatorStatement(self.context, $e1.v, $o.text, $e2.v, ($o.line, $o.pos))}
    ;

call_arguments returns [v] locals [s = list()] :
    '('
        (
            expr     {$s.append($expr.v)}
        )?
        (
            ',' expr {$s.append($expr.v)}
        )*
    ')'              {$v=$s}
    ;

assignment returns [v]
    : ID t='=' expr  {$v = AssignVariableStatement(self.context, $ID.text, $expr.v, ($t.line, $t.pos))}
    ;

write returns [v]
    : expr t='>>'    {$v = PrintStatement(self.context, $expr.v, ($t.line, $t.pos))}
    | t='print' expr {$v = PrintStatement(self.context, $expr.v, ($t.line, $t.pos))}
    ;

read returns [v]
    : t='>>' ID      {$v = ReadStatement(self.context, $ID.text, ($t.line, $t.pos))}
    | t='read' ID    {$v = ReadStatement(self.context, $ID.text, ($t.line, $t.pos))}
    ;

seq returns [v]
    : assignment     {$v = $assignment.v}
    | write          {$v = $write.v}
    | read           {$v = $read.v}
    | scope          {$v = $scope.v}
    | if_expr        {$v = $if_expr.v}
    | while_expr     {$v = $while_expr.v}
    | PASS           {$v = PassStatement(self.context, ($PASS.line, $PASS.pos))}
    | returnW        {$v = $returnW.v}
    | expr           {$v = ExpressionStatement(self.context, $expr.v, $expr.v._position)}
    | def_var        {$v = $def_var.v}
    | def_func       {$v = $def_func.v}
    ;

returnW returns [v]
    : RETURN expr    {$v = ReturnStatement(self.context, $expr.v, ($RETURN.line, $RETURN.pos))}
    | RETURN         {$v = ReturnStatement(self.context, None,    ($RETURN.line, $RETURN.pos))}
    ;

body returns [v] locals [s = list()] :
    (
        seq          {$s.append($seq.v)}
        (
            ';' seq  {$s.append($seq.v)}
        )*
        ';'?
    )?               {$v=$s};

def_var returns [v]
    : varType ID          {$v = DeclareVariableStatement(self.context, $varType.v, $ID.text, ($ID.line, $ID.pos))}
    | varType ID '=' expr {$v = DeclareAndAssignVariableStatement(self.context, $varType.v, $ID.text, $expr.v, ($ID.line, $ID.pos))}
    ;

root returns [v] :
                     {$v = ScopeStatement(self.context, (0, 0))}
    body             {$v.build($body.v)}
    ;

scope returns [v] :
    s='{'            {$v = ScopeStatement(self.context, ($s.line, $s.pos))}
        body         {$v.build($body.v)}
    e='}'
    ;

def_func returns [v] :
    funcReturnType ID function_parameters
    s='{'            {$v = FunctionStatement(self.context, $funcReturnType.v, $ID.text, $function_parameters.v, ($s.line, $s.pos))}
        body         {$v.build($body.v)}
    '}'
    ;

def_lambda returns [v] :
    funcReturnType    function_parameters
    s='{'            {$v = FunctionStatement(self.context, $funcReturnType.v, None, $function_parameters.v, ($s.line, $s.pos))}
        body         {$v.build($body.v)}
    '}'
    ;

scope_or_statement returns [v]
    : scope          {$v=$scope.v}
    |                {$v = ScopeStatement(self.context, (0, 0))}
      seq            {$v.build([$seq.v])}
    ;

while_expr returns [v]
    : w='while' e=expr s=scope_or_statement {$v = WhileStatement(self.context, $e.v, $s.v, ($w.line, $w.pos))}
    ;

if_expr returns [v]
    : i='if' e=expr t=scope_or_statement 'else' f=scope_or_statement
                     {$v = IfStatement(self.context, $e.v, $t.v, $f.v, ($i.line, $i.pos))}

    | i='if' e=expr t=scope_or_statement
                     {$v = IfStatement(self.context, $e.v, $t.v, None, ($i.line, $i.pos))}
    ;

function_parameters returns [v] locals [s = list()] :
    '('
        (    varType ID {$s.append(($varType.v, $ID.text))})?
        (',' varType ID {$s.append(($varType.v, $ID.text))})*
    ')'              {$v = $s};

funcReturnType returns [v]
    : varType        {$v=$varType.v}
    | 'void'         {$v='void'}
    ;

varType returns [v]
    : 'int'          {$v='int'}
    | 'bool'         {$v='bool'}
    | functionalType {$v = $functionalType.v}
    ;

functionalType returns [v] locals [s = list()]:
    '('
        (
            varType      {$s.append($varType.v)} | 'X' {$s.append('x')}
        )?
        (
            ',' (varType {$s.append($varType.v)} | 'X' {$s.append('x')})
        )*

    ')->' funcReturnType {$v = '(' + ','.join($s) + ')' + '->' + $funcReturnType.v}
    ;

BOOL
    : 'true'
    | 'false'
    ;

COMA : ',' ;
PASS : 'pass' ;
RETURN: 'return' ;

INT : DIGIT+ ;
ID : ALPHA (ALPHA | DIGIT | '_')* ;

COMMENT : '/*' .*? '*/' ->  channel(HIDDEN) ;
LINE_COMMENT : ('#' | '//') ~( '\r' | '\n' )* ->  channel(HIDDEN) ;
WS : [ \t\r\n]+ ->  channel(HIDDEN) ;

fragment ALPHA : [a-zA-Z] ;
fragment DIGIT : [0-9] ;

