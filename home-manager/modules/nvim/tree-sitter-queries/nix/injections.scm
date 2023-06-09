; inject into node of pkgs.makeNixosTest.testScript
(
binding
attrpath: (attrpath attr: (identifier) @_test )
expression: (indented_string_expression) @python
(#eq? @_test "testScript")
)

; inject bash into runCommand
(
apply_expression
function:  (apply_expression 
function: (apply_expression 
function: (variable_expression 
name: (identifier) @_test))) 
argument: (indented_string_expression) @bash
(#eq? @_test "runCommand")
)

; inject bash into buildPhases
(
binding
attrpath: (attrpath attr: (identifier) @_test)
expression: (indented_string_expression) @bash
(#any-of? @_test 
"unpackPhase" "preUnpack" "postUnpack"
"patchPhase" "prePatch" "postPatch"
"configurePhase" "preConfigure" "postConfigure"
"buildPhase" "preBuild" "postBuild"
"checkPhase" "preCheck" "postCheck"
"installPhase" "preInstall" "postInstall" 
"fixupPhase" "preFixup" "postFixup"
"installCheckPhase" "preInstallCheck" "postInstallCheck" 
"distPhase" "preDist" "postDist" 
)
) 
; a different variation: TODO can this be merged?
(
binding
attrpath: 
(attrpath attr: (identifier) @_test)
expression: (binary_expression) @bash
(#any-of? @_test 
"unpackPhase" "preUnpack" "postUnpack"
"patchPhase" "prePatch" "postPatch"
"configurePhase" "preConfigure" "postConfigure"
"buildPhase" "preBuild" "postBuild"
"checkPhase" "preCheck" "postCheck"
"installPhase" "preInstall" "postInstall" 
"fixupPhase" "preFixup" "postFixup"
"installCheckPhase" "preInstallCheck" "postInstallCheck" 
"distPhase" "preDist" "postDist" 
)
) 
(
binding
attrpath: (attrpath attr: (identifier) @_test)
expression: (apply_expression 
function: (apply_expression)
argument: (indented_string_expression) @bash)
(#any-of? @_test 
"unpackPhase" "preUnpack" "postUnpack"
"patchPhase" "prePatch" "postPatch"
"configurePhase" "preConfigure" "postConfigure"
"buildPhase" "preBuild" "postBuild"
"checkPhase" "preCheck" "postCheck"
"installPhase" "preInstall" "postInstall" 
"fixupPhase" "preFixup" "postFixup"
"installCheckPhase" "preInstallCheck" "postInstallCheck" 
"distPhase" "preDist" "postDist" 
)
) 


((comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (string_expression (string_fragment) @injection.content)
    (indented_string_expression (string_fragment) @injection.content)
  ]
  (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
  (#set! injection.combined))

