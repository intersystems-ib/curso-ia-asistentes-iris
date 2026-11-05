/// Small terminal helpers shared by the course labs.
Class Learning.Helper Extends %RegisteredObject
{

/// Print response text with CRLF line endings so each line starts at column one.
ClassMethod PrintResponse(text As %String)
{
    Set text = $Replace(text, $Char(13,10), $Char(10))
    Write $Replace(text, $Char(10), $Char(13,10)), !
}

}
