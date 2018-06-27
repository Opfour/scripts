//----------------------------------------------------------------------------//
    var Browser = '' ;
//----------------------------------------------------------------------------//
    if ( !document.all && document.getElementById )                                 
    { 
        Browser = 'Mozilla / Mozilla Firefox' ; 
    }
    if ( document.layers )                                                          
    { 
        Browser = 'Netscape Navigator' ;        
    }
    if ( navigator.userAgent.indexOf ( 'Opera' ) != -1 && document.getElementById ) 
    { 
        Browser = 'Opera' ;                     
    }
    if ( document.all )                                                             
    { 
        Browser = 'Internet Explorer' ;         
    }
//----------------------------------------------------------------------------//

    function Get_Element ( ID )
    {
        var Element = '' ;
        if ( Browser == 'Internet Explorer' )                               
        { 
            Element = document.all[ID] ;            
        }
        if ( Browser == 'Netscape Navigator' )                              
        { 
            Element = document.layer[ID] ;          
        }
        if ( Browser == 'Mozilla / Mozilla Firefox' || Browser == 'Opera' ) 
        { 
            Element = document.getElementById(ID) ; 
        }
        return Element ;
    }
//----------------------------------------------------------------------------//
	function Toggle_Check_Boxes ( Form , Action )
	{
	    for ( var Index = 0 ; Index < Form.length ; Index++ )
	    {
	        Field = Form.elements[Index] ;
	        if ( Field.type == 'checkbox' )
	        {
	            if ( Action == 'Check' )
	            {
	                Field.checked = true ;
	            }
	            else if ( Action == 'Un Check' )
	            {
	                Field.checked = false ;
	            }
                else if ( Action == 'Toggle' )
                {
                    if ( Field.checked == true )
                    {
                        Field.checked = false ;
                    }
                    else if ( Field.checked == false )
                    {
                        Field.checked = true ;
                    }
                }
	        }
	    }
	}
//----------------------------------------------------------------------------//
    function Validate ( This_Form )
    {
        var Error_Message = '' ;
        with ( This_Form )
        {
            if ( wget.value == '' )
            {
                Error_Message = Error_Message + '[+] Please enter a valid full path and filename to the "wget" binaries' + "\n" ;
            }
        }
        if ( Error_Message != '' )
        {
            alert ( 'Fatal Error' + "\n\n" + Error_Message ) ;
            This_Form.wget.focus ( ) ;
            return false ;
        }
        else
        {
            return true ;
        }
    }
//----------------------------------------------------------------------------//