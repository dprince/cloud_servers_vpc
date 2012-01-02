function server_update_table(url) {

    globalRefreshURL=url
    globalRefreshDivId="#servers-table"

    $.get(url, function(html_snippet) {

        $("#servers-table").html(
            html_snippet
        );

    });

}

function server_selectors() {

	$("#server-errors-dialog").dialog({
		autoOpen: false,
		modal: true,
		height: 250,
		width: 300,
		buttons: {
			Close: function() {
				$(this).dialog('close');
			}
		}
	});

	$("#server_group_select").change(function(){

		if ($('#server_group_select').attr('name') !== undefined) {
			server_group_id=document.form_server_group_servers.elements['server_group_id'].value;
            server_update_table("/servers?server_group_id="+server_group_id);
		}

	   });

}


function server_table_selectors() {

	$(".server-paginate a").click(function(e){

      e.preventDefault();
      server_update_table($(this).attr("href"));

	});

    $(".server-sort-link").click(function(e){
        e.preventDefault();
        server_update_table($(this).attr("href"));
    });

	$(".show-server-errors").click(function(e){

		e.preventDefault();

		id=(e.target+"").replace(/.*:.*\//,'');
		$("#server-errors-dialog").dialog('open');

		$.get("/server_errors.xml?server_id="+id, function(xml) {

				dialog_html="<b>Server Errors:</b><ul>";
				$("server-error", xml).each(function(index) {

					dialog_html+="<li>"+$(this).find("error-message").text()+"</li>";

				});
				dialog_html+="</ul>";
				$("#server-errors-dialog").html(dialog_html);

		});

	   });

}
