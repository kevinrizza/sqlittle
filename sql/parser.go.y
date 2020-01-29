%{
package sql
%}

%union {
	literal string
	identifier string
	signedNumber int64
	statement interface{}
	columnNameList []string
	columnName string
	columnDefList []ColumnDef
	columnDef ColumnDef
	indexedColumnList []IndexedColumn
	indexedColumn IndexedColumn
	name string
	withoutRowid bool
	unique bool
	bool bool
	collate string
	sortOrder SortOrder
	columnConstraint columnConstraint
	columnConstraintList []columnConstraint
	tableConstraint TableConstraint
	tableConstraintList []TableConstraint
	triggerAction TriggerAction
	trigger Trigger
	triggerList []Trigger
	where Expression
	expr Expression
	exprList []Expression
	float float64
}

%type<statement> program
%type<statement> selectStmt
%type<statement> createTableStmt
%type<statement> createIndexStmt
%type<identifier> identifier
%type<literal> literal
%type<signedNumber> signedNumber
%type<float> floatNumber
%type<columnName> columnName resultColumn
%type<columnNameList> columnNameList optColumnNameList resultColumnList
%type<columnDefList> columnDefList
%type<columnDef> columnDef
%type<indexedColumnList> indexedColumnList
%type<indexedColumn> indexedColumn
%type<name> typeName constraintName
%type<unique> unique
%type<withoutRowid> withoutRowid
%type<collate> collate
%type<sortOrder> sortOrder
%type<bool> autoincrement
%type<columnConstraint> columnConstraint
%type<columnConstraintList> columnConstraintList
%type<tableConstraint> tableConstraint
%type<tableConstraintList> tableConstraintList
%type<triggerAction> triggerAction
%type<trigger> trigger
%type<triggerList> triggerList
%type<where> where
%type<expr> indexedColumnExpr
%type<expr> expr
%type<exprList> exprList
%type<bool> deferrable
%type<bool> initiallyDeferred

%token ACTION
%token AND
%token ASC
%token AUTOINCREMENT
%token CASCADE
%token COLLATE
%token CONSTRAINT
%token CREATE
%token DEFAULT
%token DEFERRABLE
%token DEFERRED
%token DELETE
%token DESC
%token FOREIGN
%token FROM
%token GLOB
%token IN
%token INDEX
%token INITIALLY
%token IS
%token KEY
%token LIKE
%token MATCH
%token NO
%token NOT
%token NULL
%token ON
%token OR
%token PRIMARY
%token REFERENCES
%token REGEXP
%token RESTRICT
%token ROWID
%token SELECT
%token SET
%token TABLE
%token UNIQUE
%token UPDATE
%token WHERE
%token WITHOUT
%token<identifier> tBare tLiteral tIdentifier
%token<identifier> tOperator
%token<signedNumber> tSignedNumber
%token<float> tFloat

%%

program:
	selectStmt |
	createTableStmt |
	createIndexStmt

literal:
	tBare {
		$$ = $1
	} |
	tLiteral {
		$$ = $1
	}

identifier:
	tBare {
		$$ = $1
	} |
	tIdentifier {
		$$ = $1
	}

signedNumber:
	tSignedNumber {
		$$ = $1
	} |
	'-' signedNumber {
		$$ = - $2
	} |
	'+' signedNumber {
		$$ = $2
	}

floatNumber:
	tFloat {
		$$ = $1
	} |
	'-' floatNumber {
		$$ = - $2
	} |
	'+' floatNumber {
		$$ = $2
	}

columnName:
	identifier {
		$$ = $1
	}

columnNameList:
	columnName {
		$$ = []string{$1}
	} |
	columnNameList ',' columnName {
		$$ = append($1, $3)
	}

optColumnNameList:
	'(' columnNameList ')' {
		$$ = $2
	}

resultColumn:
	columnName {
		$$ = $1
	}

resultColumnList:
	resultColumn {
		$$ = []string{$1}
	} |
	resultColumnList ',' resultColumn {
		$$ = append($1, $3)
	}


columnConstraint:
	PRIMARY KEY sortOrder autoincrement {
		$$ = ccPrimaryKey{$3, $4}
	} |
	UNIQUE {
		$$ = ccUnique(true)
	} |
	NULL {
		$$ = ccNull(true)
	} |
	NOT NULL {
		$$ = ccNull(false)
	} |
	COLLATE identifier {
		$$ = ccCollate($2)
	} |
	DEFAULT signedNumber {
		$$ = ccDefault($2)
	} |
	DEFAULT literal {
		$$ = ccDefault($2)
	}

columnConstraintList:
	{
		$$ = nil
	} |
	columnConstraint {
		$$ = []columnConstraint{$1}
	} |
	columnConstraintList columnConstraint {
		$$ = append($1, $2)
	}

tableConstraint:
	PRIMARY KEY '(' indexedColumnList ')' {
		$$ = TablePrimaryKey{$4}
	} |
	UNIQUE '(' indexedColumnList ')' {
		$$ = TableUnique{$3}
	} |
	FOREIGN KEY '(' columnNameList ')' REFERENCES identifier optColumnNameList deferrable initiallyDeferred triggerList {
		$$ = TableForeignKey{
			Columns: $4,
			ForeignTable: $7,
			ForeignColumns: $8,
			Deferrable: $9,
			InitiallyDeferred: $10,
			Triggers: $11,
		}
	}

constraintName:
	{ } |
	CONSTRAINT identifier {
	}

tableConstraintList:
	{ } |
	',' constraintName tableConstraint {
		$$ = []TableConstraint{$3}
	} |
	tableConstraintList ',' constraintName tableConstraint {
		$$ = append($1, $4)
	}


autoincrement:
	{ } |
	AUTOINCREMENT {
		$$ = true
	}

columnDefList:
	columnDef {
		$$ = []ColumnDef{$1}
	} |
	columnDefList ',' columnDef {
		$$ = append($1, $3)
	}

columnDef:
	identifier typeName columnConstraintList {
		$$ = makeColumnDef($1, $2, $3)
	}

typeName:
	{
		$$ = ""
	} |
	identifier {
		$$ = $1
	} |
	identifier '(' signedNumber ')' {
		$$ = $1
	} |
	identifier '(' signedNumber ',' signedNumber ')' {
		$$ = $1
	}

collate:
	{ } |
	COLLATE literal {
		$$ = $2
	}

sortOrder:
	{
		$$ = Asc
	} |
	ASC {
		$$ = Asc
	} |
	DESC {
		$$ = Desc
	}

withoutRowid:
	{
		$$ = false
	} |
	WITHOUT ROWID {
		$$ = true
	}

unique:
	{
		$$ = false
	} |
	UNIQUE {
		$$ = true
	}

indexedColumnList:
	indexedColumn {
		$$ = []IndexedColumn{$1}
	} |
	indexedColumnList ',' indexedColumn {
		$$ = append($1, $3)
	}

indexedColumnExpr:
	expr {
		$$ = $1
	}

indexedColumn:
	indexedColumnExpr collate sortOrder {
		$$ = newIndexColumn($1, $2, $3)
	}

triggerAction:
	SET NULL {
		$$ = ActionSetNull
	} |
	SET DEFAULT {
		$$ = ActionSetDefault
	} |
	CASCADE {
		$$ = ActionCascade
	} |
	RESTRICT {
		$$ = ActionRestrict
	} |
	NO ACTION {
		$$ = ActionNoAction
	}

trigger:
	ON DELETE triggerAction {
		$$ = TriggerOnDelete($3)
	} |
	ON UPDATE triggerAction {
		$$ = TriggerOnUpdate($3)
	}

triggerList:
	{ } |
	triggerList trigger {
		$$ = append($1, $2)
	}

deferrable:
    { } |
    DEFERRABLE {
        $$ = true
    }

initiallyDeferred:
    { } | INITIALLY DEFERRED {
        $$ = true
    }

where:
	{ } |
	WHERE expr {
		$$ = $2
	}

expr:
	NULL {
		$$ = nil
	} |
	identifier '(' exprList ')' {
		$$ = ExFunction{$1, $3}
	} |
	signedNumber {
		$$ = $1
	} |
	floatNumber {
		$$ = $1
	} |
	tLiteral {
		$$ = $1
	} |
	tBare {
		$$ = ExColumn($1)
	} |
	tIdentifier {
		$$ = ExColumn($1)
	} |
	expr tOperator expr {
		$$ = ExBinaryOp{$2, $1, $3}
	} |
	expr '+' expr {
		$$ = ExBinaryOp{"+", $1, $3}
	} |
	expr '-' expr {
		$$ = ExBinaryOp{"-", $1, $3}
	} |
	'(' expr ')' {
		$$ = $2
	}

exprList:
	{
		$$ = nil
	} |
	expr {
		$$ = []Expression{$1}
	} |
	exprList ',' expr {
		$$ = append($1, $3)
	}

selectStmt:
	SELECT resultColumnList FROM identifier {
		yylex.(*lexer).result = SelectStmt{ Columns: $2, Table: $4 }
	}

createTableStmt:
	CREATE TABLE identifier '(' columnDefList tableConstraintList ')' withoutRowid {
		yylex.(*lexer).result = CreateTableStmt{
			Table: $3,
			Columns: $5,
			Constraints: $6,
			WithoutRowid: $8,
		}
	}

createIndexStmt:
	CREATE unique INDEX identifier ON identifier '(' indexedColumnList ')' where {
		yylex.(*lexer).result = CreateIndexStmt{
			Index: $4,
			Table: $6,
			Unique: $2,
			IndexedColumns: $8,
			Where: $10,
		}
	}
