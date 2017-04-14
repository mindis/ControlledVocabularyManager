class RelationshipsController < ApplicationController
  delegate :relationship_form_repository, :all_relationships_query, :to => :injector
  delegate :deprecate_relationship_form_repository, :to => :deprecate_injector
  delegate :term_form_repository, :to => :term_injector
  skip_before_filter :require_admin, :only => [:review_update, :mark_reviewed]

  include GitInterface
  def index
    #Grab all relationships
    @relationships = all_relationships_query.call
  end

  def new
    @parent_relationship = relationship_form_repository.new
    @child_relationship = relationship_form_repository.new
    @parent_relationship.attributes["hier_parent"] << params["term_id"]
    @child_relationship.attributes["hier_child"] << params["term_id"]
  end

  def create
    #Create new relationship form repository
    relationship_form = relationship_form_repository.new(params[:relationship][:id])
    if params[:vocabulary]["hier_parent"].first.empty?
      flash[:notice] = "You must provide both a parent and a child when saving a relationship"
      redirect_to :action => "new", :term_id => params[:vocabulary]["hier_child"]
      return
    end
    if params[:vocabulary]["hier_child"].first.empty?
      flash[:notice] = "You must provide both a parent and a child when saving a relationship"
      redirect_to :action => "new", :term_id => params[:vocabulary]["hier_parent"]
      return
    end
    parent_exists = validate_parent_exists
    child_exists = validate_child_exists
    unless parent_exists
      flash[:notice] = "The parent you provided does not exist. Check the id and try again."
      redirect_to :action => "new", :term_id => params[:vocabulary]["hier_child"]
      return
    end
    unless child_exists
      flash[:notice] = "The child you provided does not exist. Check the id and try again."
      redirect_to :action => "new", :term_id => params[:vocabulary]["hier_parent"]
      return
    end
    relationship_form.attributes = vocabulary_params.except(:id)
    relationship_form.set_languages(params[:vocabulary])
    relationship_form.set_modified
    relationship_form.set_issued
    if relationship_form.is_valid?
      update_parent_term
      update_child_term
      relationship_form.add_resource
      triples = relationship_form.sort_stringify(relationship_form.single_graph)
      check = rugged_create(params[:relationship][:id], triples, "creating")
      if check
        flash[:notice] = "#{params[:relationship][:id]} has been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
      redirect_to "/relationships"
    else
      @relationship = relationship_form
      render :action => "new", :relationship => @relationship
    end
  end

  def edit
    @relationship = relationship_form_repository.find(params[:id])
  end

  def update
    edit_relationship_form = relationship_form_repository.find(params[:id])
    edit_relationship_form.attributes = vocabulary_params.except(:id)
    edit_relationship_form.set_languages(params[:vocabulary])
    edit_relationship_form.set_modified
    if edit_relationship_form.is_valid?
      triples = edit_relationship_form.sort_stringify(edit_relationship_form.single_graph)
      check = rugged_create(params[:id], triples, "updating")
      if check
        flash[:notice] = "Changes to #{params[:id]} have been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
      redirect_to "/relationships"
    else
      @relationship = edit_relationship_form
      render "edit"
    end
  end

  def deprecate
    @relationship = relationship_form_repository.find(params[:id])
  end

  def deprecate_only
    edit_relationship_form = deprecate_relationship_form_repository.find(params[:id])
    edit_relationship_form.is_replaced_by = vocabulary_params[:is_replaced_by]
    if edit_relationship_form.is_valid?
      triples = edit_relationship_form.sort_stringify(edit_relationship_form.single_graph)
      check = rugged_create(params[:id], triples, "updating")
      if check
        flash[:notice] = "Changes to #{params[:id]} have been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
      redirect_to "/relationships"

    else
      @relationship = edit_relationship_form
      render "deprecate"
    end
  end


  def review_update
    if Term.exists? params[:id]
      relationship_form = relationship_form_repository.find(params[:id])
      relationship_form.attributes = vocabulary_params.except(:id, :issued)
       action = "edit"
    else
      relationship_form = relationship_form_repository.new(params[:id], Relationship)
      relationship_form.attributes = vocabulary_params.except(:id, :issued)
      relationship_form.add_resource
      action = "new"
    end
    relationship_form.set_languages(params[:vocabulary])
    relationship_form.set_modified
    relationship_form.reset_issued(params[:issued])

    if relationship_form.is_valid?
      triples = relationship_form.sort_stringify(relationship_form.single_graph)
      check = rugged_create(params[:id], triples, "updating")
      if check
        flash[:notice] = "Changes to #{params[:id]} have been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
      redirect_to review_queue_path
    else
      @relationship = relationship_form
      @term = relationship_form
      render action
    end
  end

  def mark_reviewed
    if Term.exists? params[:id]
      e_params = edit_params(params[:id])
      relationship_form = relationship_form_repository.find(params[:id])
      relationship_form.attributes = ParamCleaner.call(e_params[:vocabulary].reject{|k,v| k==:language})
      relationship_form.set_languages(e_params[:vocabulary])
    else
      @relationship = reassemble(params[:id] )
      relationship_form = RelationshipForm.new(@relationship, StandardRepository.new(nil, Relationship))
    end
    branch_commit = rugged_merge(params[:id])
    if branch_commit != 0
      if relationship_form.save
        expire_page controller: 'terms', action: 'show', id: params[:id], format: :html
        expire_page controller: 'terms', action: 'show', id: params[:id], format: :jsonld
        expire_page controller: 'terms', action: 'show', id: params[:id], format: :nt
        rugged_delete_branch(params[:id])
        flash[:notice] = "#{params[:id]} has been saved and is ready for use."
        redirect_to review_queue_path
      else
        rugged_rollback(branch_commit)
        flash[:notice] = "Something went wrong, and the term was not saved."
        redirect_to review_term_path(params[:id])
      end
    else
      flash[:notice] = "Something went wrong. Please notify a systems administrator."
      redirect_to review_term_path(params[:id])
    end
  end

private

  def validate_parent_exists
    parent_exists = term_form_repository.exists?(params[:vocabulary]["hier_parent"].first)
    return false unless parent_exists
    true
  end

  def validate_child_exists
    child_exists = term_form_repository.exists?(params[:vocabulary]["hier_child"].first)
    return false unless child_exists
    true
  end

  def update_parent_term
    edit_term_form = term_form_repository.find(params[:vocabulary]["hier_parent"].first)
    edit_term_form.attributes["relationships"] << params[:relationship][:id]
    edit_term_form.set_modified
    if edit_term_form.is_valid?
      triples = edit_term_form.sort_stringify(edit_term_form.full_graph)
      binding.pry
      check = rugged_create(params[:vocabulary]["hier_parent"].first, triples, "updating")
      if check
        flash[:notice] = "#{params[:vocabulary]["hier_parent"].first} has been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
    else
      #TODO what do you do when the form is not valid.
    end
  end

  def update_child_term
    edit_term_form = term_form_repository.find(params[:vocabulary]["hier_child"].first)
    edit_term_form.attributes["relationships"] << params[:relationship][:id]
    edit_term_form.set_modified
    if edit_term_form.is_valid?
      triples = edit_term_form.sort_stringify(edit_term_form.full_graph)
      check = rugged_create(params[:vocabulary]["hier_child"].first, triples, "updating")
      if check
        flash[:notice] = "#{params[:vocabulary]["hier_child"].first} has been saved and added to the review queue."
      else
        flash[:notice] = "Something went wrong, please notify a systems administrator."
      end
    else
      #TODO what do you do when the form is not valid.
    end
  end

  def relationship_params
    ParamCleaner.call(params[:vocabulary])
  end

  def vocabulary_params
    ParamCleaner.call(params[:vocabulary])
  end

  def injector
    @injector ||= RelationshipInjector.new(params)
  end

  def term_injector
    @term_injector ||= TermInjector.new(params)
  end

  def deprecate_injector
    @injector ||= DeprecateRelationshipInjector.new(params)
  end

end