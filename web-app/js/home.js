//zk.afterMount(function() { 
//	var menuItems = jq('.menuItem');
//	menuItems.css('cursor', 'pointer');
//	menuItems.mouseenter(function() {
//		jq(this).addClass('activeMenu');
//		menuItems.each(function() {
//			if (jq(this).hasClass('activeMenu'))
//				jq(this).animate({'opacity': '1'});
//			else
//				jq(this).animate({'opacity': '0.5'}, 50);
//		})
//	})
//	menuItems.mouseleave(function() {
//		menuItems.removeClass('activeMenu');
//	})
//	jq('$boxContainer').mouseleave(function() {
//		menuItems.animate({'opacity': '1'}, 120);
//	})
//});
zk.afterMount(function() { 
	var menuItems = jq('.menuItem');
	menuItems.css('cursor', 'pointer');
	menuItems.mouseenter(function() {
		jq(this).addClass('activeMenu');
		menuItems.each(function() {
			if (jq(this).hasClass('activeMenu')){
				jq(this).css( "background-color", "#3380DD" );
				jq(this).css( "border-radius", "10px" );
			}else{
				jq(this).css( "background-color", "#EDEFF5" );
				jq(this).css( "border-radius", "10px" );
			}
		})
	})
	menuItems.mouseleave(function() {
		menuItems.removeClass('activeMenu');
	})
	jq('$boxContainer').mouseleave(function() {
		menuItems.css( "background-color", "#EDEFF5" );
		menuItems.css( "border-radius", "10px" );
	})
});