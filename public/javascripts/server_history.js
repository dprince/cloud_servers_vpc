function server_history_update_table(url) {

	globalRefreshURL=url
	globalRefreshDivId="#server-history-table"

	$.get(url, function(html_snippet) {

		$("#server-history-table").html(
			html_snippet
		);

	});

}

function server_history_selectors() {

	$("#server-history-errors-dialog").dialog({
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

}

function server_history_table_selectors() {

	$(".server-history-paginate a").click(function(e){
		 e.preventDefault();

		server_history_update_table($(this).attr("href"));

	});

    $(".server-history-sort-link").click(function(e){
         e.preventDefault();
        server_history_update_table($(this).attr("href"));
    });

	$(".show-server-history-errors").click(function(e){

		e.preventDefault();

		id=(e.target+"").replace(/.*:.*\//,'');
		$("#server-history-errors-dialog").dialog('open');

		$.get("/server_errors.xml?server_id="+id, function(xml) {

				dialog_html="<b>Server Errors:</b><ul>";
				$("server-error", xml).each(function(index) {

					dialog_html+="<li>"+$(this).find("error-message").text()+"</li>";

				});
				dialog_html+="</ul>";
				$("#server-history-errors-dialog").html(dialog_html);

		});

	});

}
