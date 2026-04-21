# frozen_string_literal: true

# Les conditions par défaut de l'agence (taux d'honoraires 7%, jour de versement
# le 10) s'appliquent quand un mandat n'a pas de valeur négociée spécifique.
# On les stocke comme defaults de colonnes pour refléter le comportement prod
# plutôt que de laisser des NULL à interpréter côté application.
class SetMandateDefaults < ActiveRecord::Migration[8.0]
  def change
    change_column_default :mandates, :management_fee_rate, 7.0
    change_column_default :mandates, :payment_day, 10
    change_column_null :mandates, :management_fee_rate, false, 7.0
    change_column_null :mandates, :payment_day, false, 10
  end
end
