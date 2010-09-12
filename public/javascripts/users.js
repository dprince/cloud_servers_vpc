function users_search(searchParams) {

	globalRefreshURL=$("#user-search-form").attr("action")+"?"+searchParams;
	globalRefreshDivId="#users-table";

     $.get(globalRefreshURL, function(html_snippet) {

       $("#users-table").html(
			html_snippet
       );

     });
}


function user_update_table(url) {

	globalRefreshURL=url
	globalRefreshDivId="#users-table"

	$.get(url, function(html_snippet) {

		$("#users-table").html(
			html_snippet
		);

	});

}

function user_edit() {

	var post_data = $("#user-edit-form").serialize();
	$.ajax({
		url: $("#user-edit-form").attr("action")+".xml",
		type: 'POST',
		data: post_data,
		success: function(data) {
			id=$("id", data).text();
			$("#td-username-"+id).html($("username", data).text());
			$("#user-dialog").dialog('close');
		},
		error: function(data) {
			$("#user-edit-error-messages").css("display", "inline");
			err_html="<ul>";
			$("error", data.responseXML).each (function() {
				err_html+="<li>"+$(this).text()+"</li>";
			});
			err_html+="</ul>";
			$("#user-edit-error-messages-content").html(err_html);
		}
	});

}

function user_password() {

	var post_data = $("#user-password-form").serialize();
	$.ajax({
		url: $("#user-password-form").attr("action")+".xml",
		type: 'POST',
		data: post_data,
		success: function(data) {
			$("#user-dialog").dialog('close');
		},
		error: function(data) {
			$("#user-password-error-messages").css("display", "inline");
			err_html="<ul>";
			$("error", data.responseXML).each (function() {
				err_html+="<li>"+$(this).text()+"</li>";
			});
			err_html+="</ul>";
			$("#user-password-error-messages-content").html(err_html);
		}
	});

}

function user_create() {

	var post_data = $("#user-create-form").serialize();
	$.ajax({
		url: $("#user-create-form").attr("action")+".xml",
		type: 'POST',
		data: post_data,
		dataType: 'xml',
		success: function(data) {
			id=$("id", data).text();
			$("#user-dialog").dialog('close');
			$("#tabs").tabs('load', 0);
		},
		error: function(data) {
			$("#user-new-error-messages").css("display", "inline");
			err_html="<ul>";
			$(data.responseXML).find("error").each (function() {
				err_html+="<li>"+$(this).text()+"</li>";
			});
			err_html+="</ul>";
			$("#user-new-error-messages-content").html(err_html);
		}
	});

}

/* selectors for the index.html.erb */
function user_selectors() {

	$("#user-new-link").button({
				icons: {
					primary: 'ui-icon-circle-plus'
				}
	}
	);

	$(".user-create").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#user-dialog").html(
				html_snippet
		   );

			$("#user-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Save: function() { user_create() }
				}
			});

		});

	});

}

/* selectors for the _table partial */
function user_table_selectors() {

	$(".user-paginate > a").click(function(e){
		 e.preventDefault();
		user_update_table($(this).attr("href"));
	});

	$(".user-sort-link").click(function(e){
		 e.preventDefault();
		user_update_table($(this).attr("href"));
	});

	$(".user-show").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#user-dialog").html(
				html_snippet
		   );

			$("#user-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Ok: function() {
						$(this).dialog('close');
					}
				}
			});

		 });

	   });

	$(".user-edit").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#user-dialog").html(
				html_snippet
		   );

			$("#user-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Save: function() { user_edit(); }
				}
			});

		 });

	   });

	$(".user-password").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#user-dialog").html(
				html_snippet
		   );

			$("#user-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Save: function() { user_password(); }
				}
			});

		 });

	   });

	$(".user-delete").click(function(e){

		e.preventDefault();

		if (!confirm("Delete user?")) {
			return;
		}

		$.ajax({
			url: $(this).attr("href")+".xml",
			type: 'POST',
			data: { _method: 'delete' },
			success: function(data) {
				id=$("id", data).text();
				$("#tr-user-"+id).remove();
			},
			error: function(data) {
				alert('Error: Failed to delete record.');
			}
		});

	   });

}
