
$(document).ready(function(){
	$.getJSON("result", function(data){


		$.each(data, function(name, value) {
			var tmpldata = { id: name, data: value };
			var tmpl = $.templates("#myTemplate");
			var tmplNav = $.templates("#navItemTemplate");
			console.log("navappend: " + name);
			$("#optionlist").append( tmpl.render(tmpldata));
			$("#navbar-left").append( tmplNav.render({name: name}));


		});
	}).fail(function(){
		console.log("An error has occurred.");
	});
});

