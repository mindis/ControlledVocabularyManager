# Repository that returns a decorated Relationship object with RelationshipForm
# validations.
class RelationshipFormRepository < Struct.new(:decorators)
  delegate :new, :find, :exists?, :to => :repository

  def repository
    DecoratingRepository.new(decorators, Relationship)
  end

  private

  def decorators
    result = super || NullDecorator.new
    DecoratorList.new(result, term_form_decorator)
  end

  def term_form_decorator
    DecoratorWithArguments.new(RelationshipForm, StandardRepository.new(nil, Relationship))
  end
end