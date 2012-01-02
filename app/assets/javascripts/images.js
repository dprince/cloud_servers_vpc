function images_search(searchParams) {

	globalRefreshURL=$("#image-search-form").attr("action")+"?"+searchParams;
	globalRefreshDivId="#images-table";

     $.get(globalRefreshURL, function(html_snippet) {

       $("#images-table").html(
			html_snippet
       );

     });
}


function image_update_table(url) {

	globalRefreshURL=url
	globalRefreshDivId="#images-table"

	$.get(url, function(html_snippet) {

		$("#images-table").html(
			html_snippet
		);

	});

}

function image_edit() {

	var post_data = $("#image-edit-form").serialize();
	$.ajax({
		url: $("#image-edit-form").attr("action")+".xml",
		type: 'POST',
		data: post_data,
		success: function(data) {
			id=$("id", data).text();
			$("#td-imagename-"+id).html($("imagename", data).text());
			$("#image-dialog").dialog('close');
			$("#image-dialog").dialog('destroy');
		},
		error: function(data) {
			$("#image-edit-error-messages").css("display", "inline");
			err_html="<ul>";
			$("error", data.responseXML).each (function() {
				err_html+="<li>"+$(this).text()+"</li>";
			});
			err_html+="</ul>";
			$("#image-edit-error-messages-content").html(err_html);
		}
	});

}

/* selectors for the index.html.erb */
function image_selectors() {

	$("#images-sync-link").button({
				icons: {
					primary: 'ui-icon-circle-plus'
				}
	}
	);

    $(".images-sync").click(function(e){
        e.preventDefault();

        $.post($(this).attr("href"), function(html_snippet) {
          refreshDiv();
          alert('Image sync scheduled.');
        });

    });

}

/* selectors for the _table partial */
function image_table_selectors() {

	$(".image-paginate > a").click(function(e){
		 e.preventDefault();
		image_update_table($(this).attr("href"));
	});

	$(".image-sort-link").click(function(e){
		 e.preventDefault();
		image_update_table($(this).attr("href"));
	});

	$(".image-show").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#image-dialog").html(
				html_snippet
		   );

			$("#image-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Ok: function() {
						$(this).dialog('close');
						$(this).dialog('destroy');
					}
				}
			});

		 });

	   });

	$(".image-edit").click(function(e){
		 e.preventDefault();

		 $.get($(this).attr("href"), function(html_snippet) {

		   $("#image-dialog").html(
				html_snippet
		   );

			$("#image-dialog").dialog({
				modal: true,
				height: 400,
				width: 600,
				buttons: {
					Save: function() { image_edit(); }
				}
			});

		 });

	   });

	$(".image-delete").click(function(e){

		e.preventDefault();

		if (!confirm("Delete image?")) {
			return;
		}

		$.ajax({
			url: $(this).attr("href")+".xml",
			type: 'POST',
			data: { _method: 'delete' },
			success: function(data) {
                refreshDiv();
			},
			error: function(data) {
				alert('Error: Failed to delete record.');
			}
		});

	   });

}
