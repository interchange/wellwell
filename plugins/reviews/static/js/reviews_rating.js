function ReviewsRating (name, id, max_rating, cur_rating, img_empty, img_full) {
	// parameters
	this.name = name;
	this.id = id;
	this.max_rating = max_rating;
	this.img_empty = img_empty;
	this.img_full = img_full;

	// initialization
	this.rating = cur_rating;
	this.pics = new Array();

	// methods
	this.rate = function (rating,name) {
		this.update(rating,name);
	}

	this.getpics = function() {
		if (this.pics.length == 0) {
			for (i = 1; i <= this.max_rating; i++) {
				this.pics[i] = document.getElementById(this.id + i);
			}
		}
	}

	this.update = function (rating,name) {
		var i = 1;

		this.getpics();
		this.rating = rating;
		document.forms[name].elements[this.name].value=rating;
		for (i = 1; i <= this.max_rating; i++) {
			if (i <= rating) {
				this.pics[i].src=this.img_full;
			}
			else {
				this.pics[i].src=this.img_empty;
			}
		}
	}
}

function reviews_rating_setup (name, id, max_rating, cur_rating, img_empty, img_full) {
	var review = new ReviewsRating(name, id, max_rating, cur_rating, img_empty, img_full);

	return review;
}
